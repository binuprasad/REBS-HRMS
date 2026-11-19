enum SyncStatus {
  pendingSync,
  synced,
  rejected;

  String get displayName {
    switch (this) {
      case SyncStatus.pendingSync:
        return 'Pending Sync';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.rejected:
        return 'Rejected';
    }
  }

  static SyncStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'synced':
        return SyncStatus.synced;
      case 'rejected':
        return SyncStatus.rejected;
      case 'pending':
      case 'pendingsync':
      case 'pending_sync':
      default:
        return SyncStatus.pendingSync;
    }
  }
}
