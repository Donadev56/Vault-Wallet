// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/types/types.dart';
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
    this.dialogPadding = const EdgeInsets.all(20.0),
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

  Widget _buildDialogHeader(String title, AppColors colors) {
    return Text(
      title,
      style: GoogleFonts.roboto(
          color: colors.textColor, fontSize: 20, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInfoRow(
      String label, String value, bool isRequestFrom, AppColors colors) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text("$label: ",
            style: GoogleFonts.roboto(
                color: colors.textColor, fontWeight: FontWeight.bold)),
        Text(value,
            style: GoogleFonts.roboto(
                color: isRequestFrom
                    ? Colors.orange
                    : colors.textColor.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required String cancelText,
    required String confirmText,
    required AppColors colors,
  }) {
    return LayoutBuilder(builder: (ctx, c) {
      final width = c.maxWidth;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          PrimaryButton(
            width: width * 0.58,
            colors: colors,
            onPressed: () async => Navigator.pop(context, true),
            text: confirmText,
            mode: ButtonMode.confirm,
            style: _theme.buttonConfirmStyle,
          ),
          PrimaryButton(
            width: width * 0.38,
            colors: colors,
            onPressed: () async => Navigator.pop(context, false),
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
            BoxConstraints(maxHeight: MediaQuery.of(context).size.width * 0.3),
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
          _buildDialogHeader(
              '$appName request to connect to your wallet?', colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Request from', requestFrom, true, colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow(
              'Address', address.ellipsisMidWalletAddress(), false, colors),
          Divider(color: colors.secondaryColor.withOpacity(0.3)),
          _buildPermissionsSection(colors, context),
          SizedBox(height: _theme.itemSpacing * 2),
          _buildActionButtons(
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
    return Column(
      children: [
        Text('Permission',
            style: GoogleFonts.roboto(
                color: colors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        SizedBox(height: _theme.itemSpacing),
        Text(
          'Do you want this site to do the following?',
          style: GoogleFonts.roboto(color: colors.textColor.withOpacity(0.5)),
        ),
        SizedBox(height: _theme.itemSpacing),
        _buildContainer(
          context: context,
          colors: colors,
          child: Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                  'See address, account balance, activity and suggest transactions to approve',
                  style: GoogleFonts.roboto(
                      color: colors.textColor.withOpacity(0.8)))
            ],
          ),
        ),
        SizedBox(height: _theme.itemSpacing),
        Text(
          'Only connect with sites you trust.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(color: colors.textColor.withOpacity(0.8)),
        ),
      ],
    );
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
        padding: _theme.dialogPadding,
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

    return await _showDialog(
      colors: colors,
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('Sign Message', colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Request from', requestFrom, true, colors),
          Divider(color: _theme.borderColor),
          Text('Message to sign:',
              style:
                  GoogleFonts.roboto(color: colors.textColor.withOpacity(0.8))),
          SizedBox(height: _theme.itemSpacing),
          GestureDetector(
            onTap: () => AppUtils.copyToClipboard(message),
            child: _buildContainer(
              context: context,
              colors: colors,
              child: Text(message,
                  style: GoogleFonts.roboto(
                      color: colors.textColor.withOpacity(0.8))),
            ),
          ),
          SizedBox(height: _theme.itemSpacing * 2),
          _buildActionButtons(
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

    return await _showDialog(
      colors: colors,
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: _theme.contentPadding,
        children: [
          _buildDialogHeader('Transaction Request', colors),
          if (value != null) ...[
            SizedBox(height: _theme.itemSpacing),
            _buildContainer(
                context: context,
                colors: colors,
                backgroundColor: colors.secondaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      AppUtils.formatCoin(
                        BigInt.parse(value).parseEther(),
                        symbol: "",
                        decimalDigits: 9,
                      ),
                      style: GoogleFonts.roboto(
                          color: colors.textColor.withOpacity(0.8),
                          fontSize: 21,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(network.chainName.toUpperCase(),
                        style: GoogleFonts.roboto(
                            color: colors.textColor.withOpacity(0.3),
                            fontSize: 21,
                            fontWeight: FontWeight.bold))
                  ],
                ) /*_buildInfoRow(
                'Value',
                AppUtils.formatCoin(
                  BigInt.parse(value).parseGwei(),
                  symbol: "",
                  decimalDigits: 9,
                ),
              ),*/
                ),
          ],
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Request from', requestFrom, true, colors),
          Divider(color: _theme.borderColor),
          _buildInfoRow('From', from.ellipsisMidWalletAddress(), false, colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('To', to.ellipsisMidWalletAddress(), false, colors),
          SizedBox(height: _theme.itemSpacing),
          Text('Details',
              style:
                  GoogleFonts.roboto(color: colors.textColor.withOpacity(0.8))),
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
              style:
                  GoogleFonts.roboto(color: colors.textColor.withOpacity(0.8)),
            ),
            SizedBox(height: _theme.itemSpacing),
            _buildContainer(
              context: context,
              colors: colors,
              child: Text(data.toString(),
                  style: GoogleFonts.roboto(
                      color: colors.textColor.withOpacity(0.8))),
            ),
          ],
          SizedBox(height: _theme.itemSpacing * 2),
          _buildActionButtons(
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
          _buildDialogHeader('Switch Network?', colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain ID', chain.chainId.toString(), false, colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain Name', chain.chainName, false, colors),
          if (chain.nativeCurrency?.symbol != null) ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow(
                'Currency', chain.nativeCurrency!.symbol, false, colors),
          ],
          if (chain.nativeCurrency?.decimals != null) ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow('Decimals', chain.nativeCurrency!.decimals.toString(),
                false, colors),
          ],
          SizedBox(height: _theme.itemSpacing * 2),
          _buildActionButtons(
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
          _buildDialogHeader('Add Network?', colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain ID', network.chainId.toString(), false, colors),
          SizedBox(height: _theme.itemSpacing),
          _buildInfoRow('Chain Name', network.chainName, false, colors),
          if (network.nativeCurrency?.symbol != null) ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow(
                'Currency', network.nativeCurrency!.symbol, false, colors),
          ],
          if (network.nativeCurrency?.decimals != null) ...[
            SizedBox(height: _theme.itemSpacing),
            _buildInfoRow('Decimals',
                network.nativeCurrency!.decimals.toString(), false, colors),
          ],
          SizedBox(height: _theme.itemSpacing * 2),
          _buildActionButtons(
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
