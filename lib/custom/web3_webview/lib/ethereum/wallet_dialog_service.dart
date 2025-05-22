// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/dialogs/row_details.dart';
import 'package:moonwallet/widgets/dialogs/standard_container.dart';
import 'package:moonwallet/widgets/func/discover/network_image.dart';
import 'package:moonwallet/widgets/func/transactions/transactions_body/transaction_app_bar.dart';
import 'package:moonwallet/widgets/screen_widgets/positioned_icon_container.dart';
import '../utils/app_utils.dart';
import '../widgets/bottom_sheet_dialog.dart';
import '../models/button_config.dart';
import '../models/models.dart';
import '../widgets/primary_button.dart';

class WalletDialogTheme {
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;
  final Color gradientColor;
  final Color primaryColor;
  final TextStyle headerStyle;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final ButtonConfig buttonConfirmStyle;
  final ButtonConfig buttonRejectStyle;
  final EdgeInsets dialogPadding;
  final EdgeInsets contentPadding;
  final double itemSpacing;

  WalletDialogTheme({
    this.textColor = const Color(0xFF1F2937),
    this.borderColor = const Color(0xFFE5E7EB),
    this.backgroundColor = Colors.white,
    this.gradientColor = const Color(0xFFE0E0E0),
    this.primaryColor = const Color(0xFF2196F3),
    this.headerStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1F2937),
    ),
    this.labelStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Color(0xFF1F2937),
    ),
    this.valueStyle = const TextStyle(
      color: Color(0xFF1F2937),
    ),
    ButtonConfig? buttonConfirmStyle,
    ButtonConfig? buttonRejectStyle,
    this.dialogPadding =
        const EdgeInsets.symmetric(vertical: 10, horizontal: 15.0),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 20.0),
    this.itemSpacing = 10.0,
  })  : buttonConfirmStyle = buttonConfirmStyle ?? const ButtonConfig(),
        buttonRejectStyle = buttonRejectStyle ?? const ButtonConfig();

  WalletDialogTheme copyWith({
    Color? textColor,
    Color? borderColor,
    Color? backgroundColor,
    Color? gradientColor,
    Color? primaryColor,
    TextStyle? headerStyle,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    ButtonConfig? buttonConfirmStyle,
    ButtonConfig? buttonRejectStyle,
    EdgeInsets? dialogPadding,
    EdgeInsets? contentPadding,
    double? itemSpacing,
  }) {
    return WalletDialogTheme(
      textColor: textColor ?? this.textColor,
      borderColor: borderColor ?? this.borderColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradientColor: gradientColor ?? this.gradientColor,
      primaryColor: primaryColor ?? this.primaryColor,
      headerStyle: headerStyle ?? this.headerStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      valueStyle: valueStyle ?? this.valueStyle,
      buttonConfirmStyle: buttonConfirmStyle ?? this.buttonConfirmStyle,
      buttonRejectStyle: buttonRejectStyle ?? this.buttonRejectStyle,
      dialogPadding: dialogPadding ?? this.dialogPadding,
      contentPadding: contentPadding ?? this.contentPadding,
      itemSpacing: itemSpacing ?? this.itemSpacing,
    );
  }
}

class WalletDialogService {
  // Singleton pattern
  WalletDialogService._();
  static final WalletDialogService instance = WalletDialogService._();

  // Theme instance
  WalletDialogTheme _theme = WalletDialogTheme();

  // Getter for current theme
  WalletDialogTheme get theme => _theme;

  // Configure theme method
  void configureTheme(WalletDialogTheme theme) {
    _theme = theme;
  }

  Widget _buildDialogHeader(
      String title, AppColors colors, BuildContext context) {
    return TransactionAppBar(
        padding: const EdgeInsets.only(bottom: 10),
        colors: colors,
        title: title,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            icon: Icon(FeatherIcons.x, color: colors.textColor),
          )
        ]);
  }

  Widget buildConnectionImage(
      String dappUrl, AppColors colors, BuildContext context) {
    final textTheme = TextTheme.of(context);

    return LayoutBuilder(builder: (ctx, c) {
      final elements = [
        ClipRRect(
          key: ValueKey("vault"),
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            ("assets/icon/filled/icon1.png"),
            width: 70,
            height: 70,
          ),
        ),
        ClipRRect(
            key: ValueKey(dappUrl),
            borderRadius: BorderRadius.circular(50),
            child: CustomNetworkImage(
              url: "https://www.google.com/s2/favicons?sz=64&domain=$dappUrl",
              size: 70,
              colors: colors,
              imageSizeOf: (v) => v,
              cover: true,
              placeholderSize: 70,
            )),
      ];
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        alignment: AlignmentDirectional.center,
        child: Column(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 80,
              child: PositionedIcons(
                colors: colors,
                imageSizeOf: (v) => v,
                gap: 50,
                children: elements,
              ),
            ),
            Text(
              "Connect to Website",
              style: textTheme.bodyMedium
                  ?.copyWith(fontSize: 15, fontWeight: FontWeight.w400),
            ),
            SizedBox(
              height: 5,
            )
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(
      String label, String value, bool isImportant, AppColors colors) {
    return RowDetailsContent(
      colors: colors,
      name: label,
      value: value,
      copyOnClick: isImportant,
      valueColor: isImportant ? Colors.orange : null,
    );
  }

  Widget buildActionButtons(
      {required BuildContext context,
      required String cancelText,
      required String confirmText,
      required AppColors colors,
      void Function()? onConfirmPress,
      void Function()? onCancelPress}) {
    return LayoutBuilder(builder: (ctx, c) {
      final width = c.maxWidth;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          PrimaryButton(
            width: width * 0.60,
            colors: colors,
            onPressed:
                onConfirmPress ?? () async => Navigator.pop(context, true),
            text: confirmText,
            mode: ButtonMode.confirm,
            style: _theme.buttonConfirmStyle,
          ),
          PrimaryButton(
            width: width * 0.36,
            colors: colors,
            onPressed:
                onCancelPress ?? () async => Navigator.pop(context, false),
            text: cancelText,
            mode: ButtonMode.reject,
            style: _theme.buttonRejectStyle,
          ),
        ],
      );
    });
  }

  Widget _buildContainer(
      {required Widget child,
      Color? backgroundColor,
      EdgeInsets? padding,
      required BuildContext context,
      required AppColors colors}) {
    return GestureDetector(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
        child: Container(
          padding: padding ?? _theme.dialogPadding,
          decoration: BoxDecoration(
            color: backgroundColor ?? colors.secondaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableRegion(
              selectionControls: materialTextSelectionControls,
              child: SingleChildScrollView(
                child: child,
              )),
        ),
      ),
    );
  }

  Future<bool?> showConnectWallet(
    BuildContext context, {
    required String address,
    required InAppWebViewController ctrl,
    required String appName,
    required AppColors colors,
  }) async {
    final requestFrom = (await ctrl.getUrl())?.host ?? '';

    return await _showDialog(
      colors: colors,
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          buildConnectionImage(requestFrom, colors, context),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Request from', requestFrom, true, colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow(
              'Address', address.ellipsisMidWalletAddress(), false, colors),
          Divider(color: colors.secondaryColor.withOpacity(0.3)),
          _buildPermissionsSection(colors, context),
          SizedBox(height: _theme.itemSpacing * 2),
          buildActionButtons(
            colors: colors,
            context: context,
            cancelText: 'Reject',
            confirmText: 'Connect',
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection(AppColors colors, BuildContext context) {
    final textTheme = TextTheme.of(context);
    return Column(
      children: [
        SizedBox(height: 15),
        Align(
          alignment: Alignment.center,
          child: Text(
            'Do you want this site to do the following?',
            textAlign: TextAlign.start,
            style: textTheme.bodyMedium?.copyWith(
                color: colors.textColor.withOpacity(0.5), fontSize: 12),
          ),
        ),
        SizedBox(height: 15),
        Column(
          spacing: 15,
          children: [
            buildRowWithIconDetails(
                icon: Icons.account_balance,
                color: colors.themeColor,
                text: "See your wallet balance and activity",
                textTheme: textTheme,
                colors: colors),
            buildRowWithIconDetails(
                icon: Icons.account_balance,
                color: colors.themeColor,
                text: "Send you request for transactions",
                textTheme: textTheme,
                colors: colors),
            buildRowWithIconDetails(
                icon: Icons.close,
                color: colors.redColor,
                text: "Cannot move funds without your permission",
                textTheme: textTheme,
                colors: colors)
          ],
        ),
        SizedBox(height: 25),
      ],
    );
  }

  Widget buildRowWithIconDetails(
      {required IconData icon,
      required Color color,
      double rounded = 50,
      double spacing = 20,
      required String text,
      TextStyle? textStyle,
      required TextTheme textTheme,
      required AppColors colors}) {
    return LayoutBuilder(builder: (ctx, c) {
      return Row(
        spacing: spacing,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 35,
            height: 35,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(rounded)),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          Expanded(
              child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: c.maxWidth),
            child: Text(
              text,
              overflow: TextOverflow.clip,
              style: textStyle ??
                  textTheme.bodyMedium?.copyWith(
                      color: colors.textColor.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w400),
            ),
          ))
        ],
      );
    });
  }

  Future _showDialog({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    required AppColors colors,
  }) {
    return BottomSheetDialog.instance.showView(
      colors: colors,
      context: context,
      useRootNavigator: true,
      backgroundColor: colors.primaryColor,
      child: Container(
        padding: const EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 20),
        child: builder(context),
      ),
    );
  }

  Future<bool?> showSignMessage(BuildContext context,
      {required String message,
      required String address,
      required InAppWebViewController ctrl,
      required AppColors colors}) async {
    final requestFrom = (await ctrl.getUrl())?.host ?? '';
    final textTheme = TextTheme.of(context);

    return await _showDialog(
      colors: colors,
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('Sign Message', colors, context),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Request from', requestFrom, true, colors),
          Divider(color: _theme.borderColor),
          Text('Message to sign:',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colors.textColor.withOpacity(0.8))),
          SizedBox(height: _theme.itemSpacing),
          GestureDetector(
            onTap: () => AppUtils.copyToClipboard(message),
            child: _buildContainer(
              context: context,
              colors: colors,
              child: Text(message,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colors.textColor.withOpacity(0.8))),
            ),
          ),
          SizedBox(height: _theme.itemSpacing * 2),
          buildActionButtons(
            colors: colors,
            context: context,
            cancelText: 'Reject',
            confirmText: 'Sign',
          ),
        ],
      ),
    );
  }

  Future<bool?> showTransactionConfirm(
    BuildContext context, {
    required Map<String, dynamic> txParams,
    required InAppWebViewController ctrl,
    required AppColors colors,
    required NetworkConfig network,
  }) async {
    final requestFrom = (await ctrl.getUrl())?.host ?? '';
    final String from = txParams['from'] ?? '';
    final String to = txParams['to'] ?? '';
    final value = txParams['value'];
    final data = txParams['data'];
    final gas = txParams['gas'];
    final textTheme = TextTheme.of(context);
    return await _showDialog(
      colors: colors,
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('Transaction Request', colors, context),
          if (value != null) ...[
            StandardContainer(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    AppUtils.formatCoin(
                      BigInt.parse(value).parseEther(),
                      symbol: "",
                      decimalDigits: 9,
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                        color: colors.textColor.withOpacity(0.8),
                        fontSize: 25,
                        fontWeight: FontWeight.w800),
                  ),
                  Text(network.nativeCurrency.symbol,
                      style: textTheme.bodyMedium?.copyWith(
                          color: colors.textColor.withOpacity(0.3),
                          fontSize: 25,
                          fontWeight: FontWeight.w800))
                ],
              ),
            )
          ],
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Request from', requestFrom, true, colors),
          Divider(color: _theme.borderColor),
          _buildInfoRow('From', from.ellipsisMidWalletAddress(), false, colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('To', to.ellipsisMidWalletAddress(), false, colors),
          SizedBox(height: _theme.itemSpacing),
          Text('Details',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colors.textColor.withOpacity(0.8))),
          SizedBox(height: _theme.itemSpacing),
          if (gas != null)
            _buildContainer(
              context: context,
              colors: colors,
              child: _buildInfoRow(
                  'Estimated Fee',
                  AppUtils.formatCoin(
                    BigInt.parse(gas).parseGwei(),
                    symbol: "Gwei",
                    decimalDigits: 9,
                  ),
                  false,
                  colors),
            ),
          if (data != null) ...[
            SizedBox(height: _theme.itemSpacing),
            Text(
              'Hex Data',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colors.textColor.withOpacity(0.8)),
            ),
            SizedBox(height: _theme.itemSpacing),
            _buildContainer(
              context: context,
              colors: colors,
              child: Text(data.toString(),
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colors.textColor.withOpacity(0.8))),
            ),
          ],
          SizedBox(height: _theme.itemSpacing * 2),
          buildActionButtons(
            colors: colors,
            context: context,
            cancelText: 'Reject',
            confirmText: 'Confirm',
          ),
        ],
      ),
    );
  }

  Future<bool?> showSwitchNetwork(
    BuildContext context, {
    required NetworkConfig chain,
    required AppColors colors,
  }) async {
    return await _showDialog(
      colors: colors,
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('Switch Network?', colors, context),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain ID', chain.chainId.toString(), false, colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain Name', chain.chainName, false, colors),
          ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow(
                'Currency', chain.nativeCurrency.symbol, false, colors),
          ],
          ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow('Decimals', chain.nativeCurrency.decimals.toString(),
                false, colors),
          ],
          SizedBox(height: _theme.itemSpacing * 2),
          buildActionButtons(
            colors: colors,
            context: context,
            cancelText: 'Cancel',
            confirmText: 'Confirm',
          ),
        ],
      ),
    );
  }

  Future<bool?> showAddNetwork(
    BuildContext context, {
    required NetworkConfig network,
    required AppColors colors,
  }) async {
    return await _showDialog(
      colors: colors,
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('Add Network?', colors, context),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain ID', network.chainId.toString(), false, colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain Name', network.chainName, false, colors),
          ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow(
                'Currency', network.nativeCurrency.symbol, false, colors),
          ],
          ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow('Decimals',
                network.nativeCurrency.decimals.toString(), false, colors),
          ],
          SizedBox(height: _theme.itemSpacing * 2),
          buildActionButtons(
            colors: colors,
            context: context,
            cancelText: 'Cancel',
            confirmText: 'Confirm',
          ),
        ],
      ),
    );
  }
}
