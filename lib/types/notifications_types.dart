enum AssetNotificationState { loading, completed, error }

class AssetNotification {
  final AssetNotificationState state;

  bool get isLoading => state == AssetNotificationState.loading;
  bool get isCompleted => state == AssetNotificationState.completed;
  bool get isError => state == AssetNotificationState.error;

  AssetNotification({required this.state});
}
