
import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';
import 'package:moonwallet/custom/solana/src/solana.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/balance_database.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/service/web3_interactions/svm/solana_address.dart';
import 'package:moonwallet/types/account_related_types.dart' as types;
import 'package:moonwallet/types/types.dart' ;
import 'package:moonwallet/widgets/func/account_related/show_watch_only_warning.dart';
import 'package:moonwallet/widgets/func/security/ask_derivate_key.dart';
import 'package:moonwallet/widgets/func/transactions/svm/ask_user_svm.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

class SolanaInteractionManager {
  RpcClient get _rpcClient => RpcClient("https://api.mainnet-beta.solana.com");
  final solana = Solana();
  final internet = InternetManager();
  final walletDb = WalletDbStateLess();
  final solAddress = SolanaAddress();

  Future<String> getBalanceToken(types.PublicAccount account, types.Crypto crypto) async {
  try {
    final tokenAddress = crypto.contractAddress;
    final ownerAddress = account.svmAddress;

    if (tokenAddress == null) {
      throw Exception("Invalid account");
    }

    if (ownerAddress == null) {
      throw Exception('Invalid account : user address is null');
    }

    final balance =  await solana.getTokenBalance(
      address: ownerAddress,
      tokenAddress: tokenAddress,
    );

      log("Balance of ${crypto.symbol} $balance");

      return balance is String ? balance : balance.toString() ;
    
  } catch (e) {
    logError(e.toString());
    rethrow ;
    
  }
  }

  Future<String> getBalance(types.PublicAccount account,types. Crypto crypto) async {
      final db = BalanceDatabase(account: account, crypto: crypto);
      final savedBalance = db.getBalance();
    try {
      String balance = "0";
    

     if (!(await internet.isConnected())) {
        return await savedBalance;
      }

      if (crypto.isNative) {
        balance = await getSolBalance(account, crypto);
      } else {
         balance = await getBalanceToken(account, crypto);

      }

      await db.saveData(balance);
      return balance ;
    } catch (e) {
      logError(e.toString());
     
    }

    return await savedBalance;
  }

  Future<String?> sendTransaction(
      BasicTransactionData data, AppColors colors, BuildContext context) async {
    try {
      if (data.account.isWatchOnly) {
        showWatchOnlyWaring(colors: colors, context: context);
        throw Exception("Watch only account can't send transactions");
      }
      final String to = data.addressTo;
      final String from = data.account.svmAddress ?? "";
      final String amount = data.amount;
      final String amountLamports =
          (Decimal.parse(data.amount) * Decimal.fromInt(10).pow(9).toDecimal())
              .toStringAsFixed(0);
      log("Amount Lamports ${amountLamports}");

      final confirmation = await askUserSvm(
          crypto: data.crypto,
          context: context,
          colors: colors,
          from: from,
          to: to,
          value: amount);

      if (confirmation == null || !confirmation.ok) {
        throw ("Transaction Rejected by user");
      }
      final memo = confirmation.memo;

      final deriveKey = await askDerivateKey(context: context, colors: colors);
      if (deriveKey == null) {
        throw types.InvalidPasswordException();
      }
      final privateAccount = await walletDb.getPrivateAccountUsingKey(
          deriveKey: deriveKey, account: data.account);
      final accountKey = privateAccount?.keyOrigin;

      if (accountKey == null) {
        throw "Invalid Wallet";
      }
      Ed25519HDKeyPair? wallet ;
      if (data.account.origin.isPrivateKey) {
        wallet = await solAddress.getKeyPairByPrivateKey(accountKey);
      } else {
        wallet = await solAddress.getKeyPair(accountKey);
      }

      if (wallet == null) {
        throw Exception( "Invalid Account Data");
      }

      final instructions = <Instruction>[];

      if (memo != null) {
        final memoInstruction =
            MemoInstruction(signers: [wallet.publicKey], memo: memo);
        instructions.add(memoInstruction);
      }
      final transaction = SystemInstruction.transfer(
        fundingAccount: wallet.publicKey,
        recipientAccount: Ed25519HDPublicKey.fromBase58(to),
        lamports: int.parse(amountLamports),
      );

      instructions.add(transaction);

      final message = Message(
        instructions: instructions,
      );

      final signature = await _rpcClient.signAndSendTransaction(
          message, [wallet]).withLoading(context, colors, "Sending...");
      log("Message signed $signature");

      return signature;
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<String> getSolBalance (types.PublicAccount account,types. Crypto crypto) async {
    try {
   
      final ownerAddress = account.svmAddress;
      if (ownerAddress == null) {
        throw Exception("Invalid account");
      }

      final solBalance = await solana.getBalance(address: ownerAddress);
      log("Solana balance $solBalance");
      return solBalance.toString();
      
    } catch (e) {
      logError(e.toString());
      rethrow ;
      
    }
  }
  /*
  Future<TransactionReceiptData?> getReceipt(String hash) async {
    try {
      final transaction = await _rpcClient.getTransaction(hash);
      if (transaction != null) {
        return TransactionReceiptData(
            from: "",
            to: "",
            transactionId: hash,
            block: transaction.slot.toString(),
            status: null);
      }
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
  */
}
