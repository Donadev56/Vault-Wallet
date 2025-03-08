import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/utils/themes.dart';

class ColorsManager extends Themes {
  final prefs = PublicDataManager();
  final String colorsName = "app-main-colors";
  final String appThemeName = "app-theme";
  final String defaultThemeName = "default-theme";

  List<String> availableThemes() {
    final list = allColors.keys.toList();
    return list;
  }

  List<AppColors> availableColors() {
    final list = allColors.values.toList();
    return list;
  }

  Future<bool> saveDefaultTheme({required String theme}) async {
    try {
      final listTheme = availableThemes();
      for (final colorName in listTheme) {
        if (colorName.trim() == theme.trim()) {
          await prefs.saveDataInPrefs(
              data: theme.trim(), key: defaultThemeName);
          return true;
        }
      }
      log("The theme $theme does not exist");
      return false;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<String?> getThemeName() async {
    try {
      return await prefs.getDataFromPrefs(key: defaultThemeName);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<AppColors> getDefaultTheme() async {
    try {
      final savedTheme = await getThemeName();
      if (savedTheme != null) {
        final defaultTheme = allColors[savedTheme];
        if (defaultTheme != null) {
          return defaultTheme;
        } else {
          log("Default theme not found");
          return darkColors;
        }
      } else {
        log("Default theme not found");
        return darkColors;
      }
    } catch (e) {
      logError(e.toString());
      return darkColors;
    }
  }

  Future<AppColors> getColorsFromTheme() async {
    try {
      final savedTheme = await prefs.getDataFromPrefs(key: appThemeName);

      if (savedTheme != null && (savedTheme).trim().contains("light")) {
        return lightColors;
      } else {
        return darkColors;
      }
    } catch (e) {
      logError(e.toString());
      return darkColors;
    }
  }

  Future<bool> saveThemeColors({required bool toDark}) async {
    if (toDark) {
      return await prefs.saveDataInPrefs(data: "dark", key: appThemeName);
    } else {
      return await prefs.saveDataInPrefs(data: "light", key: appThemeName);
    }
  }
}
