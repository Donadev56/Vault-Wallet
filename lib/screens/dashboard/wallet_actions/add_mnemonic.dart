import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/bottom_pin_copy.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:moonwallet/widgets/scanner/show_scanner.dart';
import 'package:page_transition/page_transition.dart';

class AddMnemonicScreen extends StatefulHookConsumerWidget {
  const AddMnemonicScreen({super.key});

  @override
  ConsumerState<AddMnemonicScreen> createState() => _AddPrivateKeyState();
}

class _AddPrivateKeyState extends ConsumerState<AddMnemonicScreen> {
  late TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  String userPassword = "";
  int attempt = 0;
  int secAttempt = 0;
  final web3Manager = WalletDatabase();
  final publicDataManager = PublicDataManager();
  bool isDarkMode = false;
  String firstPassword = "";
  String secondPassword = "";

  final MobileScannerController _mobileScannerController =
      MobileScannerController();

  AppColors colors = AppColors.defaultTheme;
  Themes themes = Themes();
  String savedThemeName = "";
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
    _textController = TextEditingController();

    super.initState();
    getSavedTheme();
  }

  bool keyTester(String data) {
    try {
      if (data.trim() != data) return false;

      if (data.contains('  ')) return false;

      final words = data.split(' ');

      if (words.length != 12) return false;

      if (words.any((word) => word.isEmpty)) return false;
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
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
    final accountsAsync = ref.watch(accountsNotifierProvider);
    final lastAccountNotifier =
        ref.watch(lastConnectedKeyIdNotifierProvider.notifier);

    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final accounts = useState<List<PublicData>>([]);

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
        final bool testResult = keyTester(_textController.text);

        if (!testResult) {
          throw Exception("Invalid Seed.");
        }
        if (_textController.text.isEmpty) {
          throw Exception("No Seed generated yet.");
        }
        final result = await web3Provider
            .saveSeed(_textController.text, userPassword, false)
            .withLoading(context, colors, "Creating Wallet");

        if (result != null) {
          await lastAccountNotifier.updateKeyId(result.keyId);
          notifySuccess("Wallet created successfully");

          Navigator.of(context).push(PageTransition(
              type: PageTransitionType.leftToRight,
              child: PagesManagerView(
                colors: colors,
              )));
        }
      } catch (e) {
        logError(e.toString());
        notifyError("Failed to save the key.");
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
            await askPassword(context: context, colors: colors, useBio: false);
        if (password.isNotEmpty) {
          setState(() {
            userPassword = password;
          });
          saveData();
        }
      } catch (e) {
        logError(e.toString());
        showCustomSnackBar(
            colors: colors,
            type: MessageType.error,
            context: context,
            message: "Error occurred while creating private key.",
            icon: Icons.error,
            iconColor: Colors.redAccent);
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
          automaticallyImplyLeading: false,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: colors.textColor,
              )),
          title: Text(
            "Mnemonic",
            style: textTheme.headlineMedium?.copyWith(
                color: colors.textColor,
                fontSize: fontSizeOf(20),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
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
                            "Add mnemonic ",
                            style: textTheme.headlineMedium?.copyWith(
                              color: colors.textColor,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Enter a mnemonic containing 12 keywords and make sure they are saved.",
                            style: textTheme.bodySmall?.copyWith(
                                color: colors.textColor.withValues(
                              alpha: 0.7,
                            )),
                          ),
                        ],
                      )),
                ),
                Container(
                  margin: const EdgeInsets.all(20),
                  child: Material(
                    color: Colors.transparent,
                    child: TextFormField(
                      inputFormatters: [SingleSpaceTextInputFormatter()],
                      validator: (value) {
                        if (value != null) {
                          final res = keyTester(value);
                          if (res) {
                            return null;
                          } else {
                            return "Invalid 12 words";
                          }
                        } else {
                          return "Please enter your 12 words";
                        }
                      },
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textColor,
                      ),
                      cursorColor: colors.themeColor,
                      minLines: 3,
                      maxLines: 5,
                      controller: _textController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.secondaryColor,
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 0, color: Colors.transparent)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 0, color: Colors.transparent)),
                        labelText: 'Mnemonic',
                        labelStyle: TextStyle(color: colors.textColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(roundedOf(10)),
                          borderSide: BorderSide(color: colors.textColor),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final data = await Clipboard.getData("text/plain");
                            if (data != null && data.text != null) {
                              log(data.toString());
                              setState(() {
                                String text = data.text ?? "";
                                _textController.text = text;
                              });
                            }
                          },
                          icon: Icon(Icons.paste, color: colors.themeColor),
                          label: Text(
                            "Paste",
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: fontSizeOf(16),
                              color: colors.themeColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.themeColor),
                            // Instead of setting an infinite width, just set the height.
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(roundedOf(30)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showScanner(
                                context: context,
                                controller: _mobileScannerController,
                                colors: colors,
                                onResult: (result) {
                                  setState(() {
                                    _textController.text = result;
                                  });
                                });
                          },
                          icon: Icon(LucideIcons.maximize,
                              color: colors.themeColor),
                          label: Text(
                            "Scan",
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: fontSizeOf(16),
                              color: colors.themeColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.themeColor),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(roundedOf(30)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: RichText(
                      text: TextSpan(children: [
                        WidgetSpan(
                            child: Row(
                          children: [
                            Icon(
                              LucideIcons.circleAlert,
                              color: Colors.pinkAccent,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text("Important :",
                                style: textTheme.bodyMedium?.copyWith(
                                    fontSize: fontSizeOf(16),
                                    color: colors.textColor,
                                    decoration: TextDecoration.none)),
                          ],
                        )),
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              "The Seed phrase is secret and is the only way to access your funds. Never share your private key with anyone and keep it in a safe place.",
                              style: textTheme.bodyMedium?.copyWith(
                                  fontSize: fontSizeOf(16),
                                  color: colors.textColor.withOpacity(0.5),
                                  decoration: TextDecoration.none),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: 20, left: 20), // Optional padding
                      child: OutlinedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryColor,
                          side: BorderSide(color: colors.themeColor, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(roundedOf(30)),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Back",
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: fontSizeOf(18),
                            color: colors.themeColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: 20, right: 20), // Optional padding
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(roundedOf(30)),
                            ),
                            backgroundColor: colors.themeColor),
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            await onSubmit();
                          }
                        },
                        child: Text(
                          "Next",
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: fontSizeOf(18),
                            color: colors.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ));
  }
}

class SingleSpaceTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final cleanedText = newValue.text.replaceAll(RegExp(r'\s{2,}'), ' ');

    List<String> words =
        cleanedText.split(' ').where((word) => word.isNotEmpty).toList();

    if (words.length == 12 && cleanedText.endsWith(' ')) {
      return oldValue;
    }

    if (words.length > 12) {
      return oldValue;
    }

    int selectionIndex =
        newValue.selection.end - (newValue.text.length - cleanedText.length);
    if (selectionIndex < 0) selectionIndex = 0;

    return TextEditingValue(
      text: cleanedText.toLowerCase(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
