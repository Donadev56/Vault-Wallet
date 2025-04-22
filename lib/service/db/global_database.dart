import 'dart:convert';

import 'package:hive_ce_flutter/adapters.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';

class GlobalDatabase {
  final boxName = "globalDatabase";

  Future<Box?> getBox() async {
    try {
      await Hive.openBox(boxName);
      return Hive.box(boxName);
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> saveListDynamicData(
      {required List<dynamic> data, required String key}) async {
    try {
      final box = await getBox();
      if (box != null) {
        await box.put(key, data);
        return true;
      }
      return false;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<dynamic> getDynamicData({required String key}) async {
    try {
      final box = await getBox();
      if (box != null) {
        final savedData = box.get(key);
        return savedData;
      }

      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> saveDynamicData(
      {required dynamic data, required String key}) async {
    try {
      final box = await getBox();
      if (box != null) {
        box.put(key, data);
        return true;
      }
      return false;
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<DataWithCache?> getCachedData({required String key}) async {
    try {
      final savedData = await getDynamicData(key: key);
      if (savedData != null) {
        return DataWithCache.fromJson(savedData);
      }
      return null;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Map<dynamic, dynamic> initData({required int time, required String data}) {
    return {
      "lastUpdate": DateTime.now().millisecondsSinceEpoch / 1000,
      "validationTime": time,
      "current_data": data,
      "last_versions": [],
    };
  }

  Future<bool> saveDataWithCache(
      {int validationTimeInSec = 3600,
      required String data,
      required String key}) async {
    try {
      final savedData = await getCachedData(key: key);
      if (savedData == null) {
        final dataToSave = initData(time: validationTimeInSec, data: data);
        return await saveDynamicData(data: jsonEncode(dataToSave), key: key);
      }
      final dataToSave = {
        "lastUpdate": savedData.lastUpdate,
        "validationTime": validationTimeInSec,
        "current_data": data,
        "last_versions": [...savedData.lastVersions, savedData.currentData],
      };
      return await saveDynamicData(data: jsonEncode(dataToSave), key: key);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
