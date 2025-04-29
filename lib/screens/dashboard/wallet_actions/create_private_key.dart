import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/service/web3_interactions/evm/addresses.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/backup/backup_related.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:page_transition/page_transition.dart';

class CreatePrivateKeyMain extends StatefulHookConsumerWidget {
  const CreatePrivateKeyMain({super.key});

  @override
  ConsumerState<CreatePrivateKeyMain> createState() => _CreatePrivateKeyState();
}

class _CreatePrivateKeyState extends ConsumerState<CreatePrivateKeyMain> {
  Map<String, dynamic>? data;
  String userPassword = "";
  int attempt = 0;

  final publicDataManager = PublicDataManager();

  bool isDarkMode = false;
  final manager = WalletDatabase();
  final ethAddresses = EthAddresses();
  PublicData? account;
  AppColors colors = AppColors.defaultTheme;

  Themes themes = Themes();
  String savedThemeName = "";
  String firstPassword = "";
  String secondPassword = "";
  Future<void> getSavedTheme() async {
    try {
      final manager = ColorsManager();
      final savedName = await manager.getThemeName();
      setState(() {
        savedThemeName = savedName ?? "";
      });
      final savedTheme = await manager.getDefaultTheme();
      setState(() {
        colors = savedTheme;
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  void initState() {
    getSavedTheme();
    WidgetsBinding.instance.addPostFrameCallback((time) async {
      await createWallet().withLoading(context, colors);
    });

    super.initState();
  }

  Future<void> createWallet() async {
    try {
      final wallet = await ethAddresses.createWallet();
      if (wallet.isNotEmpty) {
        setState(() {
          data = wallet;
        });
      } else {
        throw Exception("The key is Null");
      }
    } catch (e) {
      if (!mounted) return;
      notifyError("Failed to create a wallet");
    }
  }

  notifySuccess(String message) => showCustomSnackBar(
      context: context,
      message: message,
      colors: colors,
      type: MessageType.success);
  notifyError(String message) => showCustomSnackBar(
      context: context,
      message: message,
      colors: colors,
      type: MessageType.error);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final web3Provider = ref.read(web3ProviderNotifier);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);
    final lastAccountNotifier =
        ref.watch(lastConnectedKeyIdNotifierProvider.notifier);
    final accountsAsync = ref.watch(accountsNotifierProvider);

    final accounts = useState<List<PublicData>>([]);

    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);
 useEffect(() {
      accountsAsync.whenData((data) {
        accounts.value = data;
      });
      return null;
    }, [accountsAsync]);
    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    Future<void> saveData() async {
      try {
        if (data == null) {
          throw Exception("No key generated yet.");
        }
        final mnemonic = data!["seed"];
        if (userPassword.isEmpty) {
          throw Exception("passwords must not be empty or not equal ");
        }
        final result = await web3Provider
            .saveSeed(mnemonic, userPassword, true)
            .withLoading(context, colors, "Creating wallet");

        if (result != null) {
          lastAccountNotifier.updateKeyId(result.keyId);
          setState(() {
            account = result;
          });
          if (!mounted) return;
          notifySuccess("Wallet created successfully");
        } else {
          throw Exception("Failed to save the key.");
        }
      } catch (e) {
        logError(e.toString());
        notifyError("Failed to save the wallet.");
        setState(() {
          userPassword = "";
        });
      }
    }


      Future<PinSubmitResult> handleFirstSetupSubmit (String numbers) async {
    try {

    if (firstPassword.isEmpty) {
      setState(() {
        firstPassword = numbers;
      });
      return PinSubmitResult(
          success: true, repeat: true, newTitle: "Re-enter the password");
    } else if (firstPassword == numbers) {
      setState(() {
        secondPassword = numbers;
      });
        if (firstPassword.isEmpty || firstPassword != secondPassword) {
        throw Exception("passwords must not be empty or not equal ");
      }

      setState(() {
        userPassword = firstPassword;
      });

      saveData();
      return PinSubmitResult(success: true, repeat: false);
    } else {
      setState(() {
        firstPassword = "";
        secondPassword = "";
      });
      return PinSubmitResult(
          success: false,
          repeat: true,
          newTitle: "Enter a secure password",
          error: "Password does not match");
    }
  
      
    } catch (e) {
      logError(e.toString());
       return PinSubmitResult(
          success: false,
          repeat: true,
          newTitle: "Enter a secure password",
          error: "Password does not match");
    }
   }

    Future<void> handleSubmit() async {
      try {
        final password = await askPassword(context: context, colors: colors, useBio: false);
        if (password.isNotEmpty) {
          setState(() {
            userPassword = password;
          });
          saveData();
        }
      } catch (e) {
        logError(e.toString());
      notifyError("Error occurred while creating private key.");
      }
    }

    Future<void> onSubmit () async {
      if (accounts.value.isEmpty) {
         showPinModalBottomSheet(
                                  colors: colors,
                                  handleSubmit: handleFirstSetupSubmit,
                                  context: context,
                                  title: "Enter a secure password");
      } else {
        handleSubmit();
      }

    }
    if (data == null) {
      return Material(
        child: Center(
          child: CircularProgressIndicator(
            color: colors.themeColor,
          ),
        ),
      );
    }

    final seed = (data!["seed"] as String).split(" ");

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        backgroundColor: colors.primaryColor,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: colors.textColor,
            )),
        title: Text(
          "Wallet creation",
          style: textTheme.headlineMedium?.copyWith(
              color: colors.textColor,
              fontSize: fontSizeOf(20),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                  margin: const EdgeInsets.only(top: 25, left: 20),
                  child: Column(
                    spacing: 15,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Create new Wallet",
                        style: textTheme.headlineMedium?.copyWith(
                          color: colors.textColor,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "These 12 words are unique and confidential. They're your only way to access your data. Make sure you keep them safe and never share them with anyone.",
                        style: textTheme.bodySmall?.copyWith(
                            color: colors.textColor.withValues(
                          alpha: 0.7,
                        )),
                      ),
                    ],
                  )),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: colors.secondaryColor,
                  borderRadius: BorderRadius.circular(10)),
              child: Wrap(
                children: List.generate(seed.length, (index) {
                  final word = seed[index];
                  return MnemonicChip(
                      density: VisualDensity(vertical: -2, horizontal: -2),
                      colors: colors,
                      index: index,
                      word: word);
                }),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 30,
            ),
               Align(
                  alignment: Alignment.center,
                  child:SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,

                    child:  OutlinedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryColor,
                      side: BorderSide(color: colors.themeColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(roundedOf(30)),
                      ),
                    ),
                    onPressed: () async {
                      await onSubmit();
                      Navigator.of(context).push(PageTransition(
                          type: PageTransitionType.leftToRight,
                          child: PagesManagerView(
                            colors: colors,
                          )));
                    },
                    child: Text(
                      "Start Using",
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: fontSizeOf(14),
                        color: colors.themeColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),

                  ),
                )
          ],
        ),
      ),
    );
  }
}
