enum RequestStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

class ServiceRequest {
  final String id;
  final String customerName;
  final String customerPhone;
  final String serviceName;
  final String serviceCategory;
  final DateTime requestedDate;
  final String requestedTime;
  final RequestStatus status;
  final double price;
  final String specialInstructions;
  final DateTime createdAt;

  ServiceRequest({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.serviceName,
    required this.serviceCategory,
    required this.requestedDate,
    required this.requestedTime,
    required this.status,
    required this.price,
    required this.specialInstructions,
    required this.createdAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceCategory: json['serviceCategory'] ?? '',
      requestedDate: DateTime.parse(json['requestedDate'] ?? DateTime.now().toIso8601String()),
      requestedTime: json['requestedTime'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.toString() == 'RequestStatus.${json['status']}',
        orElse: () => RequestStatus.pending,
      ),
      price: (json['price'] ?? 0.0).toDouble(),
      specialInstructions: json['specialInstructions'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'serviceName': serviceName,
      'serviceCategory': serviceCategory,
      'requestedDate': requestedDate.toIso8601String(),
      'requestedTime': requestedTime,
      'status': status.toString().split('.').last,
      'price': price,
      'specialInstructions': specialInstructions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ServiceRequest copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? serviceName,
    String? serviceCategory,
    DateTime? requestedDate,
    String? requestedTime,
    RequestStatus? status,
    double? price,
    String? specialInstructions,
    DateTime? createdAt,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceName: serviceName ?? this.serviceName,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      requestedDate: requestedDate ?? this.requestedDate,
      requestedTime: requestedTime ?? this.requestedTime,
      status: status ?? this.status,
      price: price ?? this.price,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get statusText {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.confirmed:
        return 'Confirmed';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get statusColor {
    switch (status) {
      case RequestStatus.pending:
        return '#FFA500'; // Orange
      case RequestStatus.confirmed:
        return '#4CAF50'; // Green
      case RequestStatus.inProgress:
        return '#2196F3'; // Blue
      case RequestStatus.completed:
        return '#9C27B0'; // Purple
      case RequestStatus.cancelled:
        return '#F44336'; // Red
    }
  }
}

