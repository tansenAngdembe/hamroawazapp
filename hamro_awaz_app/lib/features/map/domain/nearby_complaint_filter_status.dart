/// User-facing complaint status filters mapped to backend `statusId` strings.
/// User-facing complaint status filters mapped to backend `statusId` strings.
enum NearbyComplaintFilterStatus {
  newComplaint,
  pending,
  rejected,
  inProgress,
  escalated,
  resolved, // added
  closed,   // added
}

extension NearbyComplaintFilterStatusX on NearbyComplaintFilterStatus {
  /// Label shown in the dropdown (user-friendly).
  String get displayLabel {
    switch (this) {
      case NearbyComplaintFilterStatus.newComplaint:
        return 'New';
      case NearbyComplaintFilterStatus.pending:
        return 'Pending';
      case NearbyComplaintFilterStatus.rejected:
        return 'Rejected';
      case NearbyComplaintFilterStatus.inProgress:
        return 'In Progress';
      case NearbyComplaintFilterStatus.escalated:
        return 'Escalated';
      case NearbyComplaintFilterStatus.resolved: // added
        return 'Resolved';
      case NearbyComplaintFilterStatus.closed:   // added
        return 'Closed';
    }
  }

  /// Value sent to the API as `statusId`.
  String get backendStatusId {
    switch (this) {
      case NearbyComplaintFilterStatus.newComplaint:
        return 'NEW';
      case NearbyComplaintFilterStatus.pending:
        return 'IN_REVIEW';
      case NearbyComplaintFilterStatus.inProgress:
        return 'IN_PROGRESS';
      case NearbyComplaintFilterStatus.resolved:
        return 'RESOLVED';
      case NearbyComplaintFilterStatus.rejected:
        return 'REJECTED';
      case NearbyComplaintFilterStatus.closed:
        return 'CLOSED';
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
