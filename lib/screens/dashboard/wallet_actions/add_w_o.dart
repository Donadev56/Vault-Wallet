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
import 'package:moonwallet/screens/dashboard/page_manager.dart'
    show PagesManagerView;
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/backup/backup_related.dart';
import 'package:moonwallet/widgets/backup/warning_static_message.dart';
import 'package:moonwallet/widgets/buttons/elevated_low_opacity_button.dart';
import 'package:moonwallet/widgets/buttons/outlined.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';
import 'package:moonwallet/widgets/scanner/show_scanner.dart';
import 'package:page_transition/page_transition.dart';

import '../../../service/rpc_service.dart';

class AddObservationWallet extends StatefulHookConsumerWidget {
  final TokenEcosystem ecosystem;

  const AddObservationWallet({super.key, required this.ecosystem});

  @override
  ConsumerState<AddObservationWallet> createState() => _AddPrivateKeyState();
}

class _AddPrivateKeyState extends ConsumerState<AddObservationWallet> {
  late TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  String userPassword = "";
  int attempt = 0;
  int secAttempt = 0;
  late TokenEcosystem ecosystem;
  final _rpcService = RpcService();

  final web3Manager = WalletDatabase();
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
    ecosystem = widget.ecosystem;

    super.initState();
  }

  final MobileScannerController _mobileScannerController =
      MobileScannerController();

  bool keyTester(String data) {
    try {
      final address = data.trim();
      return _rpcService.validateAddressUsingType(address, ecosystem.type) ??
          false;
    } catch (e) {
      notifyError(e.toString(), context);

      return false;
    }
  }

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
            .saveWO(_textController.text.trim(), ecosystem.type)
            .withLoading(context, colors);
        if (result != null) {
          lastAccountNotifier.updateKeyId(result.keyId);

          if (!mounted) return;
          notifySuccess("Wallet added ", context);
          Navigator.of(context).push(PageTransition(
              type: PageTransitionType.leftToRight,
              child: PagesManagerView(
                colors: colors,
              )));
        } else {
          throw Exception("Failed to save the address.");
        }
      } catch (e) {
        logError(e.toString());
        notifyError("Failed to save the address.", context);
        setState(() {
          userPassword = "";
        });
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
        notifyError("An error has occurred", context);
      }
    }

    return Scaffold(
        backgroundColor: colors.primaryColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: colors.primaryColor,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.chevron_left,
                color: colors.textColor,
              )),
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
                        margin: const EdgeInsets.only(left: 20),
                        child: Column(
                          spacing: 15,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add public address",
                              style: textTheme.headlineMedium?.copyWith(
                                color: colors.textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: "Enter a valid "),
                                  TextSpan(
                                    text: ecosystem.type
                                        .toShortString()
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: " address."),
                                ],
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.textColor
                                      .withAlpha(179), // 0.7 alpha
                                ),
                              ),
                            )
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
                                    _textController.text = result;
                                  });
                            },
                            icon: Icon(LucideIcons.maximize,
                                color: colors.themeColor),
                            text: "Scan",
                          )),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  WarningStaticMessage(
                      colors: colors,
                      title: "Warning",
                      content:
                          "Please conduct your own research before adding an observation portfolio. We are not responsible for your interactions with external addresses."),
                  SizedBox(
                    height: 40,
                  ),
                ],
              )),
          bottom: Align(
            alignment: Alignment.center,
            child: SizedBox(
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
                    if (!(keyTester(_textController.text.trim()))) {
                      notifyError("Invalid Address", context);
                      return;
                    }
                    if (_formKey.currentState?.validate() ?? false) {
                      await handleSubmit();
                    }
                  },
                  text: "Next",
                ),
              ),
            ),
          ),
        ));
  }
}
