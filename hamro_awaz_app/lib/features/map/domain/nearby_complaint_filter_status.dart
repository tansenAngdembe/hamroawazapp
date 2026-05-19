/// User-facing complaint status filters mapped to backend `statusId` strings.
enum NearbyComplaintFilterStatus {
  active,
  pending,
  rejected,
  inProgress,
  escalated,
}

extension NearbyComplaintFilterStatusX on NearbyComplaintFilterStatus {
  /// Label shown in the dropdown (user-friendly).
  String get displayLabel {
    switch (this) {
      case NearbyComplaintFilterStatus.active:
        return 'Active';
      case NearbyComplaintFilterStatus.pending:
        return 'Pending';
      case NearbyComplaintFilterStatus.rejected:
        return 'Rejected';
      case NearbyComplaintFilterStatus.inProgress:
        return 'In Progress';
      case NearbyComplaintFilterStatus.escalated:
        return 'Escalated';
    }
  }

  /// Value sent to the API as `statusId`.
  String get backendStatusId {
    switch (this) {
      case NearbyComplaintFilterStatus.active:
        return 'ACTIVE';
      case NearbyComplaintFilterStatus.pending:
        return 'PENDING';
      case NearbyComplaintFilterStatus.rejected:
        return 'REJECTED';
      case NearbyComplaintFilterStatus.inProgress:
        return 'INPROGRESS';
      case NearbyComplaintFilterStatus.escalated:
        return 'ESCALATED';
    }
  }
}

/// Allowed search radii (km) for nearby complaints.
abstract final class NearbyMapRadiusOptions {
  static const double defaultKm = 20.0;
  static const List<double> values = [20.0, 50.0, 100.0, 200.0];
}
