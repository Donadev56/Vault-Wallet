import 'dart:convert';

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/db/global_database.dart';
import 'package:moonwallet/service/internet_manager.dart';
import 'package:moonwallet/types/browser.dart';
import 'package:http/http.dart' as http;

class BrowserDataRequestManager {
  final _db = GlobalDatabase();
  final internet = InternetManager();
  final dataKey = "user/global/browser-data/2";

  Future<(List<DApp>, List<Category>)?> getBrowserData() async {
    try {
      final savedData = await getSavedBrowserData();

      if (!(await internet.isConnected())) {
        return toDart(savedData);
      }
      final response = await http
          .get(Uri.parse("https://api.moonbnb.app/crypto/browser-data"));
      if (response.statusCode == 200) {
        final body = response.body;
        final jsonData = json.decode(body) as Map<dynamic, dynamic>;
        await saveResponse(jsonData);
        return toDart(jsonData);
      }
      return savedData;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  (List<DApp>, List<Category>) toDart(dynamic json) {
    final dapps = json["dapps"];
    final categories = json["categories"];
    if (dapps == null || categories == null) {
      throw Exception("Invalid data");
    }

    final listDapps = (dapps as List).map((e) => DApp.fromJson(e)).toList();
    final listCategories =
        (categories as List).map((e) => Category.fromJson(e)).toList();

    return (listDapps, listCategories);
  }

  Future<(List<DApp>, List<Category>)> getSavedDataToDart() async {
    try {
      final data = await await getSavedBrowserData();
      return toDart(data);
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Future<dynamic> getSavedBrowserData() async {
    try {
      final data = await _db.getDynamicData(key: dataKey);
      if (data == null) {
        throw Exception("No data saved");
      }
      return data;
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }

  Future<bool> saveResponse(Map<dynamic, dynamic> json) async {
    try {
      return await _db.saveDynamicData(data: json, key: dataKey);
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }
}
