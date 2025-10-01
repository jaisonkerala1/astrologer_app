import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final _unauthorizedController = StreamController<String>.broadcast();
  bool _hasNotifiedUnauthorized = false;

  Stream<String> get unauthorizedStream => _unauthorizedController.stream;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: ApiConstants.defaultHeaders,
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          final message = error.response?.data is Map<String, dynamic>
              ? (error.response?.data['message'] as String?)
              : null;
          _notifyUnauthorized(message);
        }
        handler.next(error);
      },
    ));
  }

  void _notifyUnauthorized(String? message) {
    if (!_hasNotifiedUnauthorized) {
      _hasNotifiedUnauthorized = true;
      _unauthorizedController.add(message ?? 'Session expired. Please log in again.');
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.patch(path, data: data, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> uploadFile(String path, String filePath, {String fieldName = 'file'}) async {
    try {
      FormData formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(path, data: formData);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> postMultipart(String path, {
    Map<String, dynamic>? data,
    Map<String, File>? files,
    Map<String, dynamic>? queryParameters
  }) async {
    try {
      Map<String, dynamic> formDataMap = {};

      if (data != null) {
        formDataMap.addAll(data);
      }

      if (files != null) {
        for (String key in files.keys) {
          formDataMap[key] = await MultipartFile.fromFile(files[key]!.path);
        }
      }

      FormData formData = FormData.fromMap(formDataMap);
      final response = await _dio.post(path, data: formData, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    print('API Error: ${error.type} - ${error.message}');
    print('Request URL: ${error.requestOptions.uri}');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Make sure backend server is running on port 7566.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'An error occurred';
        return 'Server Error $statusCode: $message';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Make sure backend is running on http://192.168.29.99:7566';
      case DioExceptionType.badCertificate:
        return 'Certificate error. Please try again.';
      case DioExceptionType.unknown:
        return 'Network error. Check if backend server is running.';
    }
  }

  void setAuthToken(String token) {
    _hasNotifiedUnauthorized = false;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
    _hasNotifiedUnauthorized = false;
  }

  void dispose() {
    if (!_unauthorizedController.isClosed) {
      _unauthorizedController.close();
    }
  }
}







