import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityManager {
  Future<bool> hasInternet ( ) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none) ;
  }
}