import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/screens/dashboard/settings/change_colors.dart';
import 'package:moonwallet/screens/dashboard/settings/interface_size.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/custom_options.dart';
import 'package:moonwallet/widgets/func/security/ask_password.dart';
import 'package:moonwallet/widgets/func/snackbar.dart';
import 'package:page_transition/page_transition.dart';

class SettingsPage extends StatefulHookConsumerWidget {
  final AppColors colors;
  const SettingsPage({super.key, required this.colors});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  AppColors colors = AppColors.defaultTheme;

  @override
  void initState() {
    super.initState();
    colors = widget.colors;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    final appUIConfigAsync = ref.watch(appUIConfigProvider);
    final secureConfigAsync = ref.watch(appSecureConfigProvider);
    final secureConfigNotifier = ref.watch(appSecureConfigProvider.notifier);
    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final secureConfig = useState<AppSecureConfig>(AppSecureConfig());

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
    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    useEffect(() {
      secureConfigAsync.whenData((config) {
        secureConfig.value = config;
      });
      return null;
    }, [secureConfigAsync]);

    double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    Future<void> updateEnableBio(bool v) async {
      try {
        final password =
            await askPassword(useBio: false, context: context, colors: colors);

        if (password.isEmpty) {
          notifyError("Invalid password");
          return;
        }
        final result = await secureConfigNotifier.toggleCanUseBio(v, password);
        if (result) {
          notifySuccess(v ? "Enabled" : "Disabled");

          return;
        }

        notifyError("An error has occurred");
      } catch (e) {
        logError(e.toString());
      }
    }

    Future<void> updateLockAtStartup(bool v) async {
      try {
        final password =
            await askPassword(context: context, colors: colors, useBio: false);
        if (password.isEmpty) {
          log("No password provided");
          return;
        }
        final result = await secureConfigNotifier.updateConfig(
            password: password, lockAtStartup: v);
        if (result) {
          notifySuccess(v ? "Enabled" : "Disabled");
        }
      } catch (e) {
        logError(e.toString());
        notifyError(e.toString());
      }
    }

    final options = [
      {
        "title": "Appearance",
        "description":
            "Change the appearance of the application according to your preferences.",
        "elements": [
          {
            "name": "Change App Theme",
            "icon": Icon(
              Icons.palette,
              color: colors.textColor,
              size: iconSizeOf(30),
            ),
            "onPressed": () => Navigator.push(
                context,
                PageTransition(
                    type: PageTransitionType.fade,
                    child: ChangeThemeView(
                      colors: colors,
                    )))
          },
          {
            "name": "Interface size",
            "icon": Icon(
              Icons.format_size,
              color: colors.textColor,
              size: iconSizeOf(30),
            ),
            "onPressed": () => Navigator.push(
                context,
                PageTransition(
                    type: PageTransitionType.fade,
                    child: InterfaceSizeView(
                      colors: colors,
                    )))
          },
        ]
      },
      {
        "title": "Security",
        "elements": [
          {
            "name": "Enable biometric",
            "icon": Icon(
              Icons.fingerprint,
              color: colors.textColor,
              size: iconSizeOf(30),
            ),
            "onPressed": () => log(""),
            "trailing": Switch(
              value: secureConfig.value.useBioMetric,
              onChanged: updateEnableBio,
            )
          },
          {
            "name": "Lock app on launch",
            "icon": Icon(
              Icons.lock,
              color: colors.textColor,
              size: iconSizeOf(30),
            ),
            "onPressed": () => log("Hello world"),
            "trailing": Switch(
              value: secureConfig.value.lockAtStartup,
              onChanged: updateLockAtStartup,
            )
          },
        ]
      }
    ];

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        backgroundColor: colors.primaryColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings",
          style: textTheme.bodyMedium
              ?.copyWith(color: colors.textColor, fontSize: fontSizeOf(20)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              "Settings",
              style: textTheme.headlineMedium?.copyWith(
                  color: colors.textColor,
                  fontSize: fontSizeOf(20),
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 15,
            ),
            Column(
              children: List.generate(options.length, (i) {
                final option = options[i];
                final title = option["title"] as String;
                final desc = option["description"] as String?;
                final elements = option["elements"] as List<dynamic>;

                return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: CustomOptionWidget(
                      description: desc,
                      containerRadius: BorderRadius.circular(roundedOf(10)),
                      shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(roundedOf(10))),
                      colors: colors,
                      spaceName: title,
                      spaceNameStyle: textTheme.bodyMedium?.copyWith(
                            color: colors.textColor,
                            fontWeight: FontWeight.bold,
                          ) ??
                          TextStyle(),
                      options: List.generate(elements.length, (i) {
                        final element = elements[i];
                        final name = element["name"];
                        final icon = element["icon"];
                        final trailing = element["trailing"];
                        final onPressed = element["onPressed"] as dynamic;

                        return Option(
                            onPressed: onPressed,
                            titleStyle: textTheme.bodyMedium
                                ?.copyWith(color: colors.textColor),
                            title: name,
                            icon: icon,
                            trailing: trailing ??
                                Icon(
                                  size: iconSizeOf(30),
                                  Icons.chevron_right,
                                  color: colors.textColor.withOpacity(0.5),
                                ),
                            color: colors.secondaryColor);
                      }),
                    ));
              }),
            )
          ],
        ),
      ),
    );
  }
}
