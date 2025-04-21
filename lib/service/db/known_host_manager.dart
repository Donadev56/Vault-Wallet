import 'dart:convert';

import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/utils/prefs.dart';

class KnownHostManager {
  final prefs = PublicDataManager();
  final key = 'known_hosts';
  Future<List<dynamic>> getKnownHost({required String address}) async {
    try {
      final data = await prefs.getDataFromPrefs(key: '$key/$address');
      if (data != null) {
        return json.decode(data);
      } else {
        return [];
      }
    } catch (e) {
      logError('Error getting known hosts: $e');
      return [];
    }
  }

  Future<bool> saveKnownHostList(
      {required String address, required List<dynamic> hosts}) async {
    try {
      return await prefs.saveDataInPrefs(
          key: '$key/$address', data: json.encode(hosts));
    } catch (e) {
      logError('Error adding known host: $e');
      return false;
    }
  }

  Future<bool> addSingleKnownHost(
      {required String address, required String host}) async {
    try {
      log("Adding $host for address : $address");
      final currentHosts = await getKnownHost(address: address);
      if (!currentHosts.contains(host)) {
        currentHosts.add(host);
        return await saveKnownHostList(address: address, hosts: currentHosts);
      } else {
        return true;
      }
    } catch (e) {
      logError('Error adding known host: $e');
      return false;
    }
  }
}
