class OfflineQueuedException implements Exception {
  final String message;
  OfflineQueuedException(this.message);
  
  @override
  String toString() => message;
}
