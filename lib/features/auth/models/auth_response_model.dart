import 'astrologer_model.dart';

class AuthResponseModel {
  final bool success;
  final String message;
  final String? token;
  final AstrologerModel? astrologer;
  final String? otpId;

  AuthResponseModel({
    required this.success,
    required this.message,
    this.token,
    this.astrologer,
    this.otpId,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      astrologer: json['astrologer'] != null 
          ? AstrologerModel.fromJson(json['astrologer']) 
          : null,
      otpId: json['otpId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'astrologer': astrologer?.toJson(),
      'otpId': otpId,
    };
  }
}









