import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
import 'package:moonwallet/service/address_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/backup/backup_related.dart';
import 'package:moonwallet/widgets/bottom_pin.dart';
import 'package:moonwallet/widgets/buttons/elevated_low_opacity_button.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:page_transition/page_transition.dart';

class CreateMnemonicMain extends StatefulHookConsumerWidget {
  const CreateMnemonicMain({super.key});

  @override
  ConsumerState<CreateMnemonicMain> createState() => _CreateMnemonicKeyState();
}

class _CreateMnemonicKeyState extends ConsumerState<CreateMnemonicMain> {
  String? mnemonic;
  String userPassword = "";
  int attempt = 0;

  bool isDarkMode = false;
  final manager = WalletDatabase();
  final addressManager = AddressManager();
  PublicAccount? account;
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
      final result = addressManager.generateMnemonic();
      if (result.isNotEmpty) {
        setState(() {
          mnemonic = result;
        });
      }
    } catch (e) {
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

    final accounts = useState<List<PublicAccount>>([]);

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

    Future<void> saveData() async {
      try {
        if (mnemonic == null) {
          throw Exception("No key generated yet.");
        }

        if (userPassword.isEmpty) {
          throw Exception("passwords must not be empty or not equal ");
        }
        final result = await web3Provider
            .saveMnemonic(mnemonic!, userPassword, true)
            .withLoading(context, colors, "Creating wallet");

        if (result != null) {
          await lastAccountNotifier.updateKeyId(result.keyId);
          await Future.delayed(Duration(seconds: 3))
              .withLoading(context, colors)
              .then((_) {
            Navigator.of(context).push(PageTransition(
                type: PageTransitionType.leftToRight,
                child: PagesManagerView(
                  colors: colors,
                )));
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

    Future<PinSubmitResult> handleFirstSetupSubmit(String numbers) async {
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
        final password =
            await askUserPassword(context: context, colors: colors) ?? "";
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

    Future<void> onSubmit() async {
      if (accounts.value.isEmpty) {
        await showPinModalBottomSheet(
            colors: colors,
            handleSubmit: handleFirstSetupSubmit,
            context: context,
            title: "Enter a secure password");
      } else {
        await handleSubmit();
      }
    }

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        backgroundColor: colors.primaryColor,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.chevron_left,
              color: colors.textColor,
            )),
      ),
      body: SpaceWithFixedBottom(
          body: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                    margin: const EdgeInsets.only(left: 20),
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
                child: mnemonic == null
                    ? CircularProgressIndicator(
                        color: colors.themeColor,
                      )
                    : Wrap(
                        children:
                            List.generate(mnemonic!.split(" ").length, (index) {
                          final word = mnemonic!.split(' ')[index];
                          return MnemonicChip(
                              density:
                                  VisualDensity(vertical: -2, horizontal: -2),
                              colors: colors,
                              index: index,
                              word: word);
                        }),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          bottom: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: ElevatedLowOpacityButton(
                  colors: colors,
                  onPressed: () async {
                    await onSubmit();
                  },
                  text: "Start Using",
                ),
              ),
            ),
          )),
    );
  }
}
