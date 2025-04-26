import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/app_secure_config_notifier.dart';
import 'package:moonwallet/screens/dashboard/page_manager.dart';
import 'package:moonwallet/service/db/wallet_db.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';

class SecureCheckView extends StatefulWidget {
  final AppColors colors;
  const SecureCheckView({super.key, required this.colors});

  @override
  State<SecureCheckView> createState() => _SecureCheckViewState();
}

class _SecureCheckViewState extends State<SecureCheckView> {
  AppColors colors = AppColors.defaultTheme;
  final AppSecureConfig secureConfig = AppSecureConfig();
  bool isLoading = true;

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
  void initState() {
    super.initState();
    colors = widget.colors;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSecureConfig();
    });
  }

  Future<void> _promptForPassword() async {
    try {
      final walletStorage = WalletDatabase();
      final password = await askPassword(context: context, colors: colors);

      if (password.isNotEmpty) {
        final result = await walletStorage.isPasswordValid(password);

        if (!result) {
          notifyError("Invalid Password");
          return;
        }

        goToDashboard();
      }
    } catch (e) {
      logError(e.toString());
      notifyError(e.toString());
    }
  }

  Future<void> _checkSecureConfig() async {
    try {
      final config = await AppSecureConfigNotifier().getSecureConfig();
      final lockAtStartup = config.lockAtStartup;
      if (lockAtStartup) {
        setState(() {
          isLoading = false;
        });

        _promptForPassword();
        return;
      }
      goToDashboard();
    } catch (e) {
      logError(e.toString());
      notifyError(e.toString());
    }
  }

  void goToDashboard() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (ctx) => PagesManagerView(
                  colors: colors,
                )));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    if (isLoading) {
      return Container(
        decoration: BoxDecoration(color: colors.primaryColor),
        child: Center(
          child: SizedBox(
            height: 30,
            width: 30,
            child: LoadingAnimationWidget.discreteCircle(
                color: colors.themeColor, size: 40),
          ),
        ),
      );
    }
    return Scaffold(
        backgroundColor: colors.primaryColor,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                Text(
                  "Enter Passcode",
                  style: textTheme.headlineMedium
                      ?.copyWith(color: colors.textColor, fontSize: 20),
                ),
                IconButton(
                    onPressed: _checkSecureConfig,
                    icon: Icon(
                      Icons.fingerprint,
                      color: colors.textColor,
                    ))
              ],
            ),
          ),
        ));
  }
}
