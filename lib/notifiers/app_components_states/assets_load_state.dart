import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/types/notifications_types.dart';

class AssetsLoadState extends StateNotifier<AssetNotification> {
  AssetsLoadState()
      : super(AssetNotification(state: AssetNotificationState.loading));

  void updateState(AssetNotificationState newState) {
    state = AssetNotification(state: newState);
  }
}
