import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/screen_widgets/account_list_title_widget.dart';
import 'package:moonwallet/widgets/actions.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class InterfaceSizeView extends StatefulHookConsumerWidget {
  final AppColors colors;

  const InterfaceSizeView({super.key, required this.colors});

  @override
  ConsumerState<InterfaceSizeView> createState() => _InterfaceSizeViewState();
}

class _InterfaceSizeViewState extends ConsumerState<InterfaceSizeView> {
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
    final appUIConfigNotifier = ref.watch(appUIConfigProvider.notifier);
    final currentAccountAsync = ref.watch(currentAccountProvider);

    final uiConfig = useState<AppUIConfig>(AppUIConfig.defaultConfig);
    final account = useState<PublicData?>(null);

    useEffect(() {
      currentAccountAsync.whenData((acc) => account.value = acc);
      return null;
    }, []);
    useEffect(() {
      appUIConfigAsync.whenData((data) {
        uiConfig.value = data;
      });
      return null;
    }, [appUIConfigAsync]);

    Future<void> updateUI(
        {double? fontSize,
        double? radius,
        double? listVert,
        double? listHorizontal,
        double? imageSize,
        double? iconSize}) async {
      try {
        final res = await appUIConfigNotifier.updateAppUIConfig(
            styles: uiConfig.value.styles.copyWith(
                fontSizeScaleFactor: fontSize,
                radiusScaleFactor: radius,
                listTitleVisualDensityHorizontalFactor: listHorizontal,
                listTitleVisualDensityVerticalFactor: listVert,
                imageSizeScaleFactor: imageSize,
                iconSizeScaleFactor: iconSize));
        if (res) {
          log("Edited ");
        }
      } catch (e) {
        logError(e.toString());
      }
    }

    double iconSizeOf(double size) {
      return size * uiConfig.value.styles.iconSizeScaleFactor;
    }

    double imageSizeOf(double size) {
      return size * uiConfig.value.styles.imageSizeScaleFactor;
    }

    double roundedOf(double size) {
      return size * uiConfig.value.styles.radiusScaleFactor;
    }

    double fontSizeOf(double size) {
      return size * uiConfig.value.styles.fontSizeScaleFactor;
    }

    double listTitleVerticalOf(double size) {
      return size * uiConfig.value.styles.listTitleVisualDensityVerticalFactor;
    }

    double listTitleHorizontalOf(double size) {
      return size *
          uiConfig.value.styles.listTitleVisualDensityHorizontalFactor;
    }

    return Scaffold(
      backgroundColor: colors.primaryColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colors.primaryColor,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: colors.textColor,
            )),
        title: Text(
          "Interface",
          style: textTheme.bodyMedium
              ?.copyWith(fontSize: fontSizeOf(20), color: colors.textColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              "Interface",
              style: textTheme.headlineMedium?.copyWith(
                  color: colors.textColor,
                  fontSize: fontSizeOf(20),
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              "Edit Font Size",
              style: textTheme.bodyMedium?.copyWith(
                  color: colors.textColor.withValues(alpha: 0.8),
                  fontSize: fontSizeOf(15)),
            ),
            SizedBox(
              height: 10,
            ),
            SfSlider(
              shouldAlwaysShowTooltip: true,
              showLabels: true,
              value: uiConfig.value.styles.fontSizeScaleFactor,
              onChanged: (v) async {
                await updateUI(fontSize: v);
              },
              min: 0.7,
              max: 1.4,
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              "Border Radius",
              style: textTheme.headlineMedium?.copyWith(
                  color: colors.textColor,
                  fontSize: fontSizeOf(20),
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Edit Border Radius",
              style: textTheme.bodyMedium?.copyWith(
                  color: colors.textColor.withValues(alpha: 0.8),
                  fontSize: fontSizeOf(15)),
            ),
            Align(
              alignment: Alignment.center,
              child: ActionsWidgets(
                color: colors.secondaryColor,
                textColor: colors.textColor,
                text: "Receive",
                onTap: () {},
                actIcon: LucideIcons.moveDownLeft,
                fontSize: fontSizeOf(12),
                iconSize: iconSizeOf(27),
                radius: roundedOf(10),
              ),
            ),
            SfSlider(
              shouldAlwaysShowTooltip: true,
              showLabels: true,
              value: uiConfig.value.styles.radiusScaleFactor,
              onChanged: (v) async {
                await updateUI(radius: v);
              },
              min: 0.1,
              max: 2.5,
            ),
            SizedBox(
              height: 15,
            ),
            Text(
              "Other ",
              style: textTheme.headlineMedium?.copyWith(
                  color: colors.textColor,
                  fontSize: fontSizeOf(20),
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Edit images size and icons size",
              style: textTheme.bodyMedium?.copyWith(
                  color: colors.textColor.withValues(alpha: 0.8),
                  fontSize: fontSizeOf(15)),
            ),
            SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.center,
              child: AccountListTitleWidget(
                  colors: colors,
                  wallet: account.value ??
                      PublicData(
                          createdLocally: false,
                          keyId: "",
                          creationDate: 0,
                          walletName: "",
                          address: "",
                          isWatchOnly: true),
                  onTap: () => log("taped"),
                  onMoreTap: () => log("more"),
                  fontSizeOf: fontSizeOf,
                  iconSizeOf: iconSizeOf,
                  imageSizeOf: imageSizeOf,
                  listTitleHorizontalOf: listTitleHorizontalOf,
                  listTitleVerticalOf: listTitleVerticalOf,
                  roundedOf: roundedOf),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Image Size",
              style: textTheme.bodyMedium?.copyWith(
                  color: colors.textColor.withValues(alpha: 0.8),
                  fontSize: fontSizeOf(15)),
            ),
            SizedBox(
              height: 10,
            ),
            SfSlider(
              shouldAlwaysShowTooltip: true,
              showLabels: true,
              value: uiConfig.value.styles.imageSizeScaleFactor,
              onChanged: (v) async {
                await updateUI(imageSize: v);
              },
              min: 0.1,
              max: 2.5,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Icon Size",
              style: textTheme.bodyMedium?.copyWith(
                  color: colors.textColor.withValues(alpha: 0.8),
                  fontSize: fontSizeOf(15)),
            ),
            SizedBox(
              height: 10,
            ),
            SfSlider(
              shouldAlwaysShowTooltip: true,
              showLabels: true,
              value: uiConfig.value.styles.iconSizeScaleFactor,
              onChanged: (v) async {
                await updateUI(iconSize: v);
              },
              min: 0.5,
              max: 1.5,
            ),
          ],
        ),
      ),
    );
  }
}
