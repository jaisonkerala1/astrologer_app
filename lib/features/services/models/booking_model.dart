import 'package:equatable/equatable.dart';
import 'delivery_method_enum.dart';
import 'time_slot_model.dart';
import 'add_on_model.dart';

class BookingModel extends Equatable {
  final String? id; // Null if not yet created
  final String serviceId;
  final String astrologerId;
  final String userId;
  
  // Booking preferences
  final DeliveryMethod deliveryMethod;
  final TimeSlotModel timeSlot;
  final List<AddOnModel> selectedAddOns;
  
  // User information
  final Map<String, dynamic> userInformation; // Dynamic form data
  final String? specialInstructions;
  final List<String>? uploadedDocuments; // URLs or file paths
  
  // Pricing
  final double servicePrice;
  final double addOnsPrice;
  final double platformFee;
  final double discount;
  final double totalAmount;
  
  // Promo code
  final String? promoCode;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    this.id,
    required this.serviceId,
    required this.astrologerId,
    required this.userId,
    required this.deliveryMethod,
    required this.timeSlot,
    this.selectedAddOns = const [],
    this.userInformation = const {},
    this.specialInstructions,
    this.uploadedDocuments,
    required this.servicePrice,
    this.addOnsPrice = 0.0,
    this.platformFee = 0.0,
    this.discount = 0.0,
    required this.totalAmount,
    this.promoCode,
    required this.createdAt,
    this.updatedAt,
  });

  // Calculate total add-ons price
  double get calculatedAddOnsPrice {
    return selectedAddOns.fold(0.0, (sum, addon) => sum + addon.price);
  }

  // Calculate final total
  double get calculatedTotal {
    return servicePrice + calculatedAddOnsPrice + platformFee - discount;
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? json['_id'],
      serviceId: json['serviceId'] ?? '',
      astrologerId: json['astrologerId'] ?? '',
      userId: json['userId'] ?? '',
      deliveryMethod: DeliveryMethod.values.firstWhere(
        (e) => e.name == json['deliveryMethod'],
        orElse: () => DeliveryMethod.videoCall,
      ),
      timeSlot: TimeSlotModel.fromJson(json['timeSlot'] ?? {}),
      selectedAddOns: (json['selectedAddOns'] as List?)
              ?.map((e) => AddOnModel.fromJson(e))
              .toList() ??
          [],
      userInformation: Map<String, dynamic>.from(json['userInformation'] ?? {}),
      specialInstructions: json['specialInstructions'],
      uploadedDocuments: json['uploadedDocuments'] != null
          ? List<String>.from(json['uploadedDocuments'])
          : null,
      servicePrice: (json['servicePrice'] ?? 0).toDouble(),
      addOnsPrice: (json['addOnsPrice'] ?? 0).toDouble(),
      platformFee: (json['platformFee'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      promoCode: json['promoCode'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'serviceId': serviceId,
      'astrologerId': astrologerId,
      'userId': userId,
      'deliveryMethod': deliveryMethod.name,
      'timeSlot': timeSlot.toJson(),
      'selectedAddOns': selectedAddOns.map((e) => e.toJson()).toList(),
      'userInformation': userInformation,
      'specialInstructions': specialInstructions,
      'uploadedDocuments': uploadedDocuments,
      'servicePrice': servicePrice,
      'addOnsPrice': addOnsPrice,
      'platformFee': platformFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'promoCode': promoCode,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? serviceId,
    String? astrologerId,
    String? userId,
    DeliveryMethod? deliveryMethod,
    TimeSlotModel? timeSlot,
    List<AddOnModel>? selectedAddOns,
    Map<String, dynamic>? userInformation,
    String? specialInstructions,
    List<String>? uploadedDocuments,
    double? servicePrice,
    double? addOnsPrice,
    double? platformFee,
    double? discount,
    double? totalAmount,
    String? promoCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      astrologerId: astrologerId ?? this.astrologerId,
      userId: userId ?? this.userId,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      timeSlot: timeSlot ?? this.timeSlot,
      selectedAddOns: selectedAddOns ?? this.selectedAddOns,
      userInformation: userInformation ?? this.userInformation,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      servicePrice: servicePrice ?? this.servicePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      platformFee: platformFee ?? this.platformFee,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      promoCode: promoCode ?? this.promoCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        serviceId,
        astrologerId,
        userId,
        deliveryMethod,
        timeSlot,
        selectedAddOns,
        userInformation,
        specialInstructions,
        uploadedDocuments,
        servicePrice,
        addOnsPrice,
        platformFee,
        discount,
        totalAmount,
        promoCode,
        createdAt,
        updatedAt,
      ];
}

