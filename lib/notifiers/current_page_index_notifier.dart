import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/utils/prefs.dart';

class CurrentPageIndexNotifier extends AsyncNotifier<int> {
  final _prefs = PublicDataManager();
  final _key = "user/global/pageManager/savedCurrentPageIndex";
  @override
  Future<int> build() => getSavedPageIndex();

  Future<int> getSavedPageIndex() async {
    try {
      final savedPageIndex = await _prefs.getDataFromPrefs(key: _key);
      if (savedPageIndex == null) return 0;

      return int.parse(savedPageIndex);
    } catch (e) {
      logError(e.toString());
      return 0;
    }
  }

  Future<bool> savePageIndex(int index) async {
    try {
      state = AsyncData(index);
      await _prefs.saveDataInPrefs(data: index.toString(), key: _key);
      log("Page index changed");
      return true;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
