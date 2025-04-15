import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/types/types.dart';

class ColorsNotifier extends AsyncNotifier<AppColors> {
  late final colorsManager = ref.read(colorsManagerProvider);
  @override
  Future<AppColors> build() => getSavedTheme();

  Future<AppColors> getSavedTheme() async {
    try {
      final savedTheme = await colorsManager.getDefaultTheme();
      return savedTheme;
    } catch (e) {
      logError(e.toString());
      return AppColors.defaultTheme;
    }
  }

  Future<void> refreshTheme() async {
    state = const AsyncLoading();
    final theme = await getSavedTheme();
    state = AsyncData(theme);
  }

  Future<bool> saveTheme(String themeName) async {
    try {
      final result = await colorsManager.saveDefaultTheme(theme: themeName);
      if (result) {
        final newState = await getSavedTheme();
        state = AsyncData(newState);
        return result;
      }
      return result;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
