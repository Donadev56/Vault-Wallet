import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart'
    show PagesManagerView;
import 'package:moonwallet/service/db/wallet_saver.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/func/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:moonwallet/widgets/scanner/show_scanner.dart';
import 'package:page_transition/page_transition.dart';

class AddObservationWallet extends ConsumerStatefulWidget {
  const AddObservationWallet({super.key});

  @override
  ConsumerState<AddObservationWallet> createState() => _AddPrivateKeyState();
}

class _AddPrivateKeyState extends ConsumerState<AddObservationWallet> {
  late TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  String userPassword = "";
  int attempt = 0;
  int secAttempt = 0;

  final web3Manager = WalletSaver();
  final publicDataManager = PublicDataManager();
  bool isDarkMode = false;
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
    getSavedTheme();
    _textController = TextEditingController();

    super.initState();
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

  bool keyTester(String data) {
    try {
      return data.startsWith("0x") && data.length == 42;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final web3Provider = ref.read(web3ProviderNotifier);

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
            .saveWO(_textController.text.trim())
            .withLoading(context, colors);
        if (result) {
          if (!mounted) return;
          notifySuccess("Wallet added ");
          Navigator.of(context).push(PageTransition(
              type: PageTransitionType.leftToRight, child: PagesManagerView()));
        } else {
          throw Exception("Failed to save the address.");
        }
      } catch (e) {
        logError(e.toString());
        notifyError("Failed to save the address.");
        setState(() {
          userPassword = "";
        });
      }
    }

    Future<void> handleSubmit() async {
      try {
        final password = await askPassword(context: context, colors: colors);
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
        body: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(color: colors.primaryColor),
            child: SafeArea(
                child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 25, left: 20),
                      child: Text(
                        "Add Public Address",
                        style: textTheme.headlineMedium?.copyWith(
                            color: colors.textColor,
                            fontSize: 24,
                            decoration: TextDecoration.none),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
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
                              return "Invalid Address";
                            }
                          } else {
                            return "Please enter the public address";
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
                          labelText: 'Address',
                          labelStyle: TextStyle(color: colors.textColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
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
                              final data =
                                  await Clipboard.getData("text/plain");
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
                                fontSize: 16,
                                color: colors.themeColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.themeColor),
                              // Instead of setting an infinite width, just set the height.
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
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
                                    _textController.text = result;
                                  });
                            },
                            icon: Icon(LucideIcons.maximize,
                                color: colors.themeColor),
                            label: Text(
                              "Scan",
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 16,
                                color: colors.themeColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.themeColor),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: 20, left: 20), // Optional padding
                        child: OutlinedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryColor,
                            side:
                                BorderSide(color: colors.themeColor, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Previous",
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 18,
                              color: colors.themeColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: 20, right: 20), // Optional padding
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: colors.themeColor),
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              await handleSubmit();
                            }
                          },
                          child: Text(
                            "Next",
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 18,
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
            )),
          ),
        ));
  }
}
