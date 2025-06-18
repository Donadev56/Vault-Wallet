import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moonwallet/custom/web3_webview/lib/utils/loading.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/screens/dashboard/wallet_actions/private/backup.dart';
import 'package:moonwallet/service/db/wallet_db_stateless.dart';
import 'package:moonwallet/service/external_data/price_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/service/rpc_service.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/encrypt_service.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:moonwallet/widgets/alerts/show_alert.dart';
import 'package:moonwallet/widgets/appBar/custom_list_title_button.dart';
import 'package:moonwallet/widgets/appBar/show_wallet_actions.dart';
import 'package:moonwallet/widgets/backup/warning_static_message.dart';
import 'package:moonwallet/widgets/buttons/elevated.dart';
import 'package:moonwallet/widgets/custom_filled_text_field.dart';
import 'package:moonwallet/widgets/dialogs/show_custom_snackbar.dart';
import 'package:moonwallet/widgets/dialogs/show_standard_sheet.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/func/tokens_config/show_select_ecosystem.dart';
import 'package:moonwallet/widgets/screen_widgets/standard_app_bar.dart';
import 'package:page_transition/page_transition.dart';

class PrivateKeyScreen extends StatefulHookConsumerWidget {
  final String? password;
  final PublicAccount account;
  final AppColors? colors;

  const PrivateKeyScreen(
      {super.key, this.password, required this.account, this.colors});

  @override
  ConsumerState<PrivateKeyScreen> createState() => _PrivateKeyScreenState();
}

class _PrivateKeyScreenState extends ConsumerState<PrivateKeyScreen> {
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

  final TextEditingController _secretController = TextEditingController();
  bool _isInitialized = false;

  final web3Manager = WalletDatabase();
  final encryptService = EncryptService();
  final priceManager = PriceManager();
  PrivateAccount? privateAccount;
  late PublicAccount account;

  String walletKeyId = "";
  String password = "";

  @override
  void initState() {
    getSavedTheme();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showWarn();
    });
    if (widget.password != null) {
      password = widget.password!;
    }
    if (widget.colors != null) {
      colors = widget.colors!;
    }
    account = widget.account;
  }

  void showWarn() {
    showWarning(
        context: context,
        colors: colors,
        title: "Warning",
        titleColor: Colors.orange,
        content: Text(
          "You are about to view sensitive information, make sure you are not in a public place and that no one is looking at your screen.",
          style: TextTheme.of(context)
              .bodyMedium
              ?.copyWith(color: Colors.pinkAccent),
        ),
        actions: [
          TextButton.icon(
            icon: Icon(
              Icons.arrow_back,
              color: colors.textColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            label: Text(
              "Go back",
              style: TextTheme.of(context)
                  .bodyMedium
                  ?.copyWith(color: colors.textColor),
            ),
          ),
          TextButton.icon(
            icon: Icon(
              Icons.remove_red_eye,
              color: colors.textColor,
            ),
            onPressed: () {
              getPrivateAccount();
              Navigator.pop(context);
            },
            label: Text(
              "View",
              style: TextTheme.of(context)
                  .bodyMedium
                  ?.copyWith(color: colors.textColor),
            ),
          ),
        ]);
  }

  Future<void> getPrivateAccount() async {
    try {
      final data = await WalletDbStateLess()
          .getPrivateAccountUsingPassword(password: password, account: account);
      if (data != null) {
        _secretController.text = data.keyOrigin;

        setState(() {
          privateAccount = data;
        });
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final data = ModalRoute.of(context)?.settings.arguments;
      if (data != null &&
          (data as Map<String, dynamic>)["keyId"] != null &&
          (data["password"] as String?) != null) {
        final keyId = data["keyId"] as String;
        final userPassword = data["password"];
        log("$keyId and $userPassword");
        setState(() {
          walletKeyId = keyId;
          password = userPassword;
        });
      }
      _isInitialized = true;
    }
  }

  double calcDouble(double value) {
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: StandardAppBar(
        title: "Wallet Source",
        fontSizeOf: calcDouble,
        colors: colors,
        actions: [
          privateAccount == null
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: colors.textColor,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: () {
                    showAppBarWalletActions(
                      context: context,
                      colors: colors,
                      children: [
                        if (privateAccount != null &&
                            privateAccount?.origin.isMnemonic == true)
                          CustomListTitleButton(
                              colors: colors,
                              text: 'Export Private Key',
                              icon: Icons.key,
                              onTap: () async {
                                final ecosystem = await showSelectEcoSystem(
                                  context: context,
                                  description:
                                      "Select the ecosystem you want to extract the private key from",
                                  colors: colors,
                                  roundedOf: calcDouble,
                                  fontSizeOf: calcDouble,
                                  iconSizeOf: calcDouble,
                                );
                                if (ecosystem == null) {
                                  return;
                                }
                                final key = await RpcService()
                                    .generatePrivateKe(
                                        ecosystem.type, _secretController.text)
                                    .withLoading(context, colors, "Loading...");

                                if (key == null) {
                                  notifyError("Something went wrong", context);
                                  return;
                                }

                                await showMaterialModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return Scaffold(
                                        backgroundColor: colors.primaryColor,
                                        appBar: StandardAppBar(
                                          
                                            title: "${ecosystem.name} key",
                                            colors: colors,
                                            fontSizeOf: calcDouble),
                                        body: StandardContainer(
                                          padding: const EdgeInsets.all(20),
                                          backgroundColor: colors.primaryColor,
                                          child: ListView(
                                            children: [
                                              CustomFilledTextFormField(
                                                colors: colors,
                                                fontSizeOf: calcDouble,
                                                iconSizeOf: calcDouble,
                                                roundedOf: calcDouble,
                                                readOnly: true,
                                                maxLines: 5,
                                                minLines: 4,
                                                hintText:
                                                    "${ecosystem.name} key",
                                                controller:
                                                    TextEditingController(
                                                        text: key),
                                              ),
                                              SizedBox(
                                                height: 30,
                                              ),
                                              CustomElevatedButton(
                                                onPressed: () {
                                                  Clipboard.setData(
                                                    ClipboardData(text: key),
                                                  );
                                                },
                                                colors: colors,
                                                text: "Copy Key",
                                                rounded: 10,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5,
                                                        horizontal: 5),
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
                                                      "The private key and Mnemonic are secret and is the only way to access your funds. Never share your private key or Mnemonic with anyone.",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    });
                              },
                              iconSizeOf: calcDouble,
                              fontSizeOf: calcDouble,
                              roundedOf: calcDouble),
                        if (privateAccount != null &&
                            privateAccount?.origin.isMnemonic == true)
                          SizedBox(
                            height: 10,
                          ),
                        CustomListTitleButton(
                            colors: colors,
                            text: 'Download Secret',
                            icon: Icons.download,
                            onTap: () {},
                            iconSizeOf: calcDouble,
                            fontSizeOf: calcDouble,
                            roundedOf: calcDouble)
                      ],
                    );
                  },
                  icon: Icon(
                    Icons.more_vert,
                    color: colors.textColor,
                  ))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            CustomFilledTextFormField(
              colors: colors,
              readOnly: true,
              fontSizeOf: calcDouble,
              iconSizeOf: calcDouble,
              roundedOf: calcDouble,
              maxLines: 5,
              minLines: 4,
              labelText: "Secret",
              controller: _secretController,
            ),
            SizedBox(
              height: 15,
            ),
            SizedBox(
              height: 15,
            ),
            if (privateAccount != null && !privateAccount?.notBackup)
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: CustomElevatedButton(
                    onPressed: () {
                      if (_secretController.text.isEmpty) {
                        notifyError("No Secret found", context);
                        return;
                      }
                      Clipboard.setData(
                        ClipboardData(text: _secretController.text),
                      );
                    },
                    colors: colors,
                    text: "Copy Secret",
                    rounded: 10,
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 5)),
              )
            else
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: CustomElevatedButton(
                  backgroundColor: Colors.orange,
                  onPressed: () => Navigator.push(
                      context,
                      PageTransition(
                          type: PageTransitionType.fade,
                          child: BackupSeedScreen(
                              publicAccount: account,
                              password: password,
                              wallet: privateAccount!,
                              colors: colors))),
                  colors: colors,
                  text: "Backup phrases",
                  rounded: 10,
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                ),
              ),
            Align(
              alignment: Alignment.topLeft,
              child: WarningStaticMessage(
                colors: colors,
                title: "Important :",
                content:
                    "The private key and Mnemonic are secret and is the only way to access your funds. Never share your private key or Mnemonic with anyone.",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
