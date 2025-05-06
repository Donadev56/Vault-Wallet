import 'package:moonwallet/custom/solana/src/Content/AppContent.dart';
import 'package:moonwallet/custom/solana/src/bip39.dart';
import 'package:moonwallet/custom/solana/src/network_extension.dart';
import 'package:moonwallet/custom/solana/src/type.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

/// A Solana.
class Solana {
  /// Returns [value]  Mnemonic values.
  Future<String> generateMnemonic() async {
    return await getMnemonic();
  }

  /// Returns [value] Solana address.
  Future<String> getSolanaAddress({required String mnemonic}) async {
    try {
      log((await isValidateMnemonic(mnemonic)).toString());
      if (await isValidateMnemonic(mnemonic) == false) {
        throw  ArgumentError('Invalid seed');
      }
      final senderWallet = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
      return senderWallet.address;
    } catch (e) {
      throw  Exception('$e');
    }
  }

  /// Returns  SolanaClient.
  SolanaClient _getClient(NetworkType networkType) {
    if (networkType == NetworkType.Mainnet) {
      return SolanaClient(
        rpcUrl: Uri.parse(Content.Mainnet_RPC),
        websocketUrl: Uri.parse(Content.Mainnet_WEBRPC),
      );
    } else {
      return SolanaClient(
        rpcUrl: Uri.parse(Content.Devnet_RPC),
        websocketUrl: Uri.parse(Content.Devnet_WEBRPC),
      );
    }
  }

  Future<Map<String, String>> sendSolCoin({
    required String receiverAddress,
    required num amount,
     NetworkType networkType = NetworkType.Mainnet,
    required String mnemonic,
    String? memo 
  }) async {
    try {

      if (await isValidateMnemonic(mnemonic) == false) {
        throw  ArgumentError('Invalid seed');
      }
      if (isValidSolanaAddress(receiverAddress) == false) {
        throw  ArgumentError('Invalid receiver address');
      }
      SolanaClient client = _getClient(networkType);

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

  Future<Map<String, String>> sendToken({
    required String receiverAddress,
    required String tokenAddress,
    required num amount,
     NetworkType networkType = NetworkType.Mainnet,
    required String mnemonic,
    String ? memo 
  }) async {
    try {
      if (await isValidateMnemonic(mnemonic) == false) {
        throw  ArgumentError('Invalid seed');
      }
      if (isValidSolanaAddress(receiverAddress) == false) {
        throw  ArgumentError('Invalid receiver address');
      }
      if (isValidSolanaAddress(tokenAddress) == false) {
        throw  ArgumentError('Invalid token address');
      }

      SolanaClient client = _getClient(networkType);

      final senderWallet = await Ed25519HDKeyPair.fromMnemonic(mnemonic);

      var sol = await client.transferSplToken(
          memo: memo ,
          amount: solToLamports(amount).toInt(),
          destination: Ed25519HDPublicKey.fromBase58(receiverAddress),
          mint: Ed25519HDPublicKey.fromBase58(tokenAddress),
          owner: senderWallet);
      return {"status": "Done", "message": sol};
    } catch (e) {
      return {"status": "Error", "message": "$e"};
    }
  }

  Future<double> getBalance({
    required String address,
     NetworkType networkType = NetworkType.Mainnet,
  }) async {
    SolanaClient client = _getClient(networkType);
    var tr = await client.rpcClient.getBalance(address);
    log((tr.value / getPrecision(9)).toString());
    return tr.value / getPrecision(9);
  }

  Future<String?> getTokenBalance(
      {required String address,
      required String tokenAddress,
     NetworkType networkType = NetworkType.Mainnet,
      }) async {
    try {
      if (isValidSolanaAddress(tokenAddress) == false) {
        throw  ArgumentError('Invalid token address');
      }
      if (isValidSolanaAddress(address) == false) {
        throw  ArgumentError('Invalid address');
      }
      SolanaClient client = _getClient(networkType);

      var tokenInfo =
          await getTokenInfo(address: tokenAddress, networkType: networkType);

      if (tokenInfo == null) {
        throw ArgumentError("An error has occurred. \n Please check again the token address .");
      }
      final owner = tokenInfo.value?.owner;
      if (owner == null) {
        throw ArgumentError("Owner cannot be null");
      }
      var tr = await client.rpcClient.getTokenAccountsByOwner(
          address,
          encoding: Encoding.jsonParsed,
          TokenAccountsFilter.byProgramId(owner));

      final accountData =  tr.value[0].account.data?.toJson();
      final info =  accountData["parsed"]["info"];
      final mint = info["mint"];
      if (mint != null && (mint as String).toLowerCase().trim() != tokenAddress.toLowerCase().trim() ) {
        return "0";
      }

      log("Account data : ${accountData.toString()}");
      log("Info : ${info.toString()}");
      return info["tokenAmount"]["uiAmountString"] ?? "0";
      
    } catch (e) {
      logError(e.toString());
      rethrow ;
    }
  }

  Future<AccountResult?> getTokenInfo(
      {required String address, 
     NetworkType networkType = NetworkType.Mainnet,
      }) async {
    SolanaClient client = _getClient(networkType);
    try {
      var tr = await client.rpcClient
          .getAccountInfo(address, encoding: Encoding.jsonParsed);
      log(tr.toJson().toString());
      return tr;
    } catch (e) {
      logError(e.toString());
      return null ;
    }
    //data['value']['owner'].toString()
  }

  Future<dynamic> getTokenTransaction(
      {required String walletAddress,
      required String tokenName,
     NetworkType networkType = NetworkType.Mainnet,
      
      }) async {
    SolanaClient client = _getClient(networkType);
    var trans = await client.rpcClient.getSignaturesForAddress(
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
      String sign, NetworkType? networkType) async {
    SolanaClient client = _getClient(networkType ?? NetworkType.Mainnet);

    var tr = await client.rpcClient.getTransaction(sign,
        encoding: Encoding.jsonParsed, commitment: Commitment.finalized);
    log(tr!.meta!.postTokenBalances.toString());
    return tr.transaction.toJson()['message']['instructions'][0];
  }
}
