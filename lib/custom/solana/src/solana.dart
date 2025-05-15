import 'dart:async';

import 'package:moonwallet/custom/solana/src/bip39.dart';
import 'package:moonwallet/custom/solana/src/enums.dart' show SolNetworkType;
import 'package:moonwallet/custom/solana/src/types.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

/// A Solana.
class Solana {
  /// Returns [value]  Mnemonic values.
  final String rpcUrl;

  Solana(this.rpcUrl);

  SolanaClient get _client => SolanaClient(
        rpcUrl: Uri.parse(rpcUrl),
        websocketUrl: Uri.parse("wss://api.mainnet-beta.solana.com"),
      );

  Future<String> generateMnemonic() async {
    return getMnemonic();
  }

  /// Returns [value] Solana address.
  Future<String> getSolanaAddress({required String mnemonic}) async {
    try {
      if (!isValidateMnemonic(mnemonic)) {
        throw ArgumentError('Invalid seed');
      }
      final senderWallet = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
      return senderWallet.address;
    } catch (e) {
      throw Exception('$e');
    }
  }

  Future<String?> sendSolCoin(
      {required String receiverAddress,
      required Ed25519HDKeyPair wallet,
      required FutureOr<void> Function(String) onSigned,
      required int amount,
      SolNetworkType networkType = SolNetworkType.Mainnet,
      String? memo}) async {
    try {
      final destination = Ed25519HDPublicKey.fromBase58(receiverAddress);

      final signature = await _client.transferLamports(
          onSigned: onSigned,
          source: wallet,
          destination: destination,
          lamports: amount);
      return signature;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<String?> sendToken(
      {required String receiverAddress,
      required String tokenAddress,
      required int amount,
      required Ed25519HDKeyPair wallet,
      SolNetworkType networkType = SolNetworkType.Mainnet,
      required FutureOr<void> Function(String) onSigned,
      String? memo}) async {
    try {
      if (!isValidSolanaAddress(receiverAddress)) {
        throw ArgumentError('Invalid receiver address');
      }
      if (!isValidSolanaAddress(tokenAddress)) {
        throw ArgumentError('Invalid token address');
      }

      final mint = Ed25519HDPublicKey.fromBase58(tokenAddress);
      final destination = Ed25519HDPublicKey.fromBase58(receiverAddress);
      if (!(await _client.hasAssociatedTokenAccount(
          owner: destination, mint: mint))) {
        final account = await _client.createAssociatedTokenAccount(
            mint: mint, funder: wallet, owner: destination);
        log("Token Account : ${account.toJson()}");
      }
      await Future.delayed(Duration(seconds: 2));
      var hash = await _client.transferSplToken(
          onSigned: onSigned,
          memo: memo,
          amount: amount,
          destination: destination,
          mint: mint,
          owner: wallet);
      return hash;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  /*
  Future<Map<String, String>> sendSolCoin({
    required String receiverAddress,
    required num amount,
     SolNetworkType networkType = SolNetworkType.Mainnet,
    required String mnemonic,
    String? memo 
  }) async {
    try {

      if (!isValidateMnemonic(mnemonic)) {
        throw  ArgumentError('Invalid seed');
      }
      if (!isValidSolanaAddress(receiverAddress)) {
        throw  ArgumentError('Invalid receiver address');
      }
      

      final senderWallet = await Ed25519HDKeyPair.fromMnemonic(mnemonic);

      var sol = await client.transferLamports(
        memo: memo,
        destination: Ed25519HDPublicKey.fromBase58(receiverAddress),
        lamports: solToLamports(amount).toInt(),
        source: senderWallet,
      );
      return {"status": "Done", "message": sol};
    } catch (e) {
      return {"status": "Error", "message": "$e"};
    }
  }
 */

  Future<double> getBalance({
    required String address,
    SolNetworkType networkType = SolNetworkType.Mainnet,
  }) async {
    var tr = await _client.rpcClient.getBalance(address);
    log((tr.value / getPrecision(9)).toString());
    return tr.value / getPrecision(9);
  }

  Future<String?> getTokenBalance({
    required String address,
    required String tokenAddress,
    SolNetworkType networkType = SolNetworkType.Mainnet,
  }) async {
    try {
      if (!isValidSolanaAddress(tokenAddress)) {
        throw ArgumentError('Invalid token address');
      }
      if (!isValidSolanaAddress(address)) {
        throw ArgumentError('Invalid address');
      }

      var tokenInfo =
          await getTokenInfo(address: tokenAddress, networkType: networkType);

      if (tokenInfo == null) {
        throw ArgumentError(
            "An error has occurred. \n Please check again the token address .");
      }
      final owner = tokenInfo.value?.owner;
      if (owner == null) {
        throw ArgumentError("Owner cannot be null");
      }
      var tr = await _client.rpcClient.getTokenAccountsByOwner(
          address,
          encoding: Encoding.jsonParsed,
          TokenAccountsFilter.byProgramId(owner));

      final accountData = tr.value[0].account.data?.toJson();
      final info = accountData["parsed"]["info"];
      final mint = info["mint"];
      if (mint != null &&
          (mint as String).toLowerCase().trim() !=
              tokenAddress.toLowerCase().trim()) {
        return "0";
      }

      log("Account data : ${accountData.toString()}");
      log("Info : ${info.toString()}");
      return info["tokenAmount"]["uiAmountString"] ?? "0";
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<AccountResult?> getTokenInfo({
    required String address,
    SolNetworkType networkType = SolNetworkType.Mainnet,
  }) async {
    try {
      var tr = await _client.rpcClient
          .getAccountInfo(address, encoding: Encoding.jsonParsed);
      log(tr.toJson().toString());
      return tr;
    } catch (e) {
      logError(e.toString());
      return null;
    }
    //data['value']['owner'].toString()
  }

  Future<dynamic> getTokenTransaction({
    required String walletAddress,
    required String tokenName,
    SolNetworkType networkType = SolNetworkType.Mainnet,
  }) async {
    var trans = await _client.rpcClient.getSignaturesForAddress(
      walletAddress,
    );
    List reportList = [];
    for (int i = 0; i < trans.length; i++) {
      var decode = await getTransactionDetails(
          trans[i].toJson()['signature'], networkType);
      if (decode.containsKey('data')) {
        continue;
      }
      if (decode['parsed']['type'] == 'transfer' &&
          decode['program'] == tokenName) {
        decode['parsed']['info']['hash'] = trans[i].toJson()['signature'];
        decode['parsed']['info']['date'] = trans[i].toJson()['blockTime'];
        reportList.add(decode['parsed']['info']);
      }
    }
    return reportList;
  }

  Future<Map<String, dynamic>> getTransactionDetails(
      String sign, SolNetworkType? networkType) async {
    var tr = await _client.rpcClient.getTransaction(sign,
        encoding: Encoding.jsonParsed, commitment: Commitment.finalized);
    log(tr!.meta!.postTokenBalances.toString());
    return tr.transaction.toJson()['message']['instructions'][0];
  }
}
