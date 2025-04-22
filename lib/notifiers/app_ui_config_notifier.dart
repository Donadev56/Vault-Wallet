
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/types/types.dart';

class AppUIConfigNotifier extends AsyncNotifier<AppUIConfig> {
  final dataKey = "userUiConfig";
  final db = GlobalDatabase();
  
  final defaultSetting = AppUIConfig(
      colors: AppColors.defaultTheme,
      isCryptoHidden: false,
      styles: AppStyle());

  @override
  Future<AppUIConfig> build() => getSavedUiConfig();

  Future<AppUIConfig> getSavedUiConfig() async {
    try {
      final savedUiConfigJson = await db.getDynamicData(key: dataKey);
      if (savedUiConfigJson != null) {
        return AppUIConfig.fromJson(savedUiConfigJson);
      }
      return defaultSetting;
    } catch (e) {
      logError(e.toString());
      return defaultSetting;
    }
  }

  Future<bool> updateAppUIConfig({
    AppColors? colors,
    AppStyle? styles,
    bool? isCryptoHidden,
  }) async {
    try {
      final lastStyles = state.value;

      final newStyles = (lastStyles ?? defaultSetting).copyWith(
        colors: colors,
        styles: styles,
        isCryptoHidden: isCryptoHidden,
      );
      return await saveUiConfig(newStyles);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<bool> saveUiConfig(AppUIConfig appStyles) async {
    try {
      final res =
          await db.saveDynamicData(data: appStyles.toJson(), key: dataKey);
      if (res) {
        state = AsyncData(appStyles);
        return res;
      }
      return res;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }


}
