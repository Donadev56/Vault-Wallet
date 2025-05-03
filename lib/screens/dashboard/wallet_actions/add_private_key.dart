import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
import 'package:moonwallet/widgets/backup/backup_related.dart';
import 'package:moonwallet/widgets/backup/warning_static_message.dart';
import 'package:moonwallet/widgets/buttons/elevated_low_opacity_button.dart';
import 'package:moonwallet/widgets/buttons/outlined.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:moonwallet/widgets/scanner/show_scanner.dart';
import 'package:page_transition/page_transition.dart';
import 'package:web3dart/web3dart.dart';

class AddPrivateKeyInMain extends StatefulHookConsumerWidget {
  const AddPrivateKeyInMain({super.key});

  @override
  ConsumerState<AddPrivateKeyInMain> createState() => _AddPrivateKeyState();
}

class _AddPrivateKeyState extends ConsumerState<AddPrivateKeyInMain> {
  late TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  String userPassword = "";
  int attempt = 0;
  int secAttempt = 0;
  final publicDataManager = PublicDataManager();
  bool isDarkMode = false;

  final manager = WalletDatabase();
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
    getSavedTheme();

    super.initState();
  }

  bool keyTester(String data) {
    try {
      final key = data.trim();
      if (key.length < 60) {
        showCustomSnackBar(
            colors: colors,
            type: MessageType.error,
            context: context,
            message: "Private key is not valid.",
            iconColor: Colors.pinkAccent);
        return false;
      }
      String hexKey;
      if (key.isEmpty) {
        showCustomSnackBar(
            colors: colors,
            type: MessageType.error,
            context: context,
            message: "Please enter a private key !",
            iconColor: Colors.pinkAccent);
        return false;
      }

      if (key.startsWith("0x")) {
        hexKey = key.substring(2);
        log("The new key is  : $hexKey");
      } else {
        hexKey = key;
      }

      Credentials fromHex = EthPrivateKey.fromHex(hexKey);
      if (fromHex.address.hex.isNotEmpty) {
        log("Address found : ${fromHex.address.hex}");
        return true;
      } else {
        return false;
      }
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

  final MobileScannerController _mobileScannerController =
      MobileScannerController();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final web3Provider = ref.read(web3ProviderNotifier);
    final appUIConfigAsync = ref.watch(appUIConfigProvider);
    final lastAccountNotifier =
        ref.watch(lastConnectedKeyIdNotifierProvider.notifier);

    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);

    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

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
          throw Exception("Invalid private key.");
        }
        if (_textController.text.isEmpty) {
          throw Exception("No key generated yet.");
        }
        final key = _textController.text.trim();
        if (userPassword.isEmpty) {
          throw Exception("passwords must not be empty ");
        }
        final result = await web3Provider
            .savePrivateKey(key, userPassword, false)
            .withLoading(context, colors, "Creating wallet");
        if (result != null) {
          lastAccountNotifier.updateKeyId(result.keyId);

          if (!mounted) return;
          notifySuccess("Wallet created successfully");
          Navigator.of(context).push(PageTransition(
              type: PageTransitionType.leftToRight,
              child: PagesManagerView(
                colors: colors,
              )));
        } else {
          throw Exception("Failed to save the key.");
        }
      } catch (e) {
        logError(e.toString());
        notifyError("Failed to save the key.");
        setState(() {
          userPassword = "";
        });
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

    return Scaffold(
        backgroundColor: colors.primaryColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colors.primaryColor,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: colors.textColor,
              )),
          title: Text(
            "Private Key",
            style: textTheme.headlineMedium?.copyWith(
                color: colors.textColor,
                fontSize: fontSizeOf(20),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none),
          ),
        ),
        body: SpaceWithFixedBottom(
            body: Form(
              key: _formKey,
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
                              "Add private key",
                              style: textTheme.headlineMedium?.copyWith(
                                color: colors.textColor,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Enter an EVM-compatible private key.",
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
                        validator: (value) {
                          if (value != null) {
                            final res = keyTester(value);
                            if (res) {
                              return null;
                            } else {
                              return "Invalid private key";
                            }
                          } else {
                            return "Please enter a private key";
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
                          labelText: 'Private Key',
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CustomOutlinedButton(
                          colors: colors,
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
                          text: "Paste",
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CustomOutlinedButton(
                          colors: colors,
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
                          text: "Scan",
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: WarningStaticMessage(
                        colors: colors,
                        title: "Important :",
                        content:
                            "The private key is secret and is the only way to access your funds. Never share your private key with anyone and keep it in a safe place."),
                  ),
                ],
              ),
            ),
            bottom: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: ElevatedLowOpacityButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: colors.themeColor,
                  ),
                  colors: colors,
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await handleSubmit();
                    }
                  },
                  text: "Next",
                ),
              ),
            )));
  }
}
