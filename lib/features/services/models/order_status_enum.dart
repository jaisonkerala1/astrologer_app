enum OrderStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  refunded,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Waiting for confirmation';
      case OrderStatus.confirmed:
        return 'Booking confirmed';
      case OrderStatus.inProgress:
        return 'Consultation in progress';
      case OrderStatus.completed:
        return 'Successfully completed';
      case OrderStatus.cancelled:
        return 'Booking cancelled';
      case OrderStatus.refunded:
        return 'Amount refunded';
    }
  }

  String get icon {
    switch (this) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.confirmed:
        return '✓';
      case OrderStatus.inProgress:
        return '▶';
      case OrderStatus.completed:
        return '✓';
      case OrderStatus.cancelled:
        return '✗';
      case OrderStatus.refunded:
        return '↩';
    }
  }

  bool get canCancel => this == OrderStatus.pending || this == OrderStatus.confirmed;
  bool get canReschedule => this == OrderStatus.pending || this == OrderStatus.confirmed;
  bool get canReview => this == OrderStatus.completed;
  bool get canDownload => this == OrderStatus.completed;
}

