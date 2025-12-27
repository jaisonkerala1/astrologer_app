import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final _unauthorizedController = StreamController<String>.broadcast();
  bool _hasNotifiedUnauthorized = false;

  Stream<String> get unauthorizedStream => _unauthorizedController.stream;

  Future<void> initialize() async {
    print('🔧 [API_SERVICE] Initializing...');
    
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

    // Load token from storage on initialization (for app restarts)
    try {
      final storage = StorageService();
      final token = await storage.getAuthToken();
      if (token != null && token.isNotEmpty) {
        setAuthToken(token);
        print('✅ [API_SERVICE] Loaded auth token from storage on initialization');
      } else {
        print('ℹ️ [API_SERVICE] No auth token found in storage');
      }
    } catch (e) {
      print('❌ [API_SERVICE] Error loading token from storage: $e');
    }
    
    print('✅ [API_SERVICE] Initialization complete');
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
      // #region agent log
      try {
        File(r'c:\Users\jaiso\Desktop\astrologer_app\.cursor\debug.log').writeAsStringSync(
          '${jsonEncode({"sessionId":"debug-session","runId":"pre-fix","hypothesisId":"A","location":"lib/core/services/api_service.dart:post","message":"ApiService.post enter","data":{"path":path,"hasData":data!=null,"hasQuery":queryParameters!=null},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      // #region agent log
      try {
        File(r'c:\Users\jaiso\Desktop\astrologer_app\.cursor\debug.log').writeAsStringSync(
          '${jsonEncode({"sessionId":"debug-session","runId":"pre-fix","hypothesisId":"A","location":"lib/core/services/api_service.dart:post","message":"ApiService.post DioException","data":{"path":path,"type":e.type.name,"statusCode":e.response?.statusCode},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion

      // #region agent log
      // Ensure debug folder exists and log to the expected file (older logs may fail if .cursor doesn't exist)
      try {
        Directory(r'c:\Users\jaiso\Desktop\astrologer_app\.cursor').createSync(recursive: true);
        File(r'c:\Users\jaiso\Desktop\astrologer_app\.cursor\debug.log').writeAsStringSync(
          '${jsonEncode({"sessionId":"debug-session","runId":"pre-fix","hypothesisId":"A","location":"lib/core/services/api_service.dart:post","message":"ApiService.post DioException (dir ensured)","data":{"path":path,"type":e.type.name,"statusCode":e.response?.statusCode},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion

      // IMPORTANT: For verification request, backend uses 400 to return "requirements not met".
      // Dio throws on 400 by default; we need to return the response so the repository can handle it.
      if (path == ApiConstants.verificationRequest &&
          e.type == DioExceptionType.badResponse &&
          e.response != null &&
          e.response?.statusCode == 400) {
        // #region agent log
        try {
          Directory(r'c:\Users\jaiso\Desktop\astrologer_app\.cursor').createSync(recursive: true);
          File(r'c:\Users\jaiso\Desktop\astrologer_app\.cursor\debug.log').writeAsStringSync(
            '${jsonEncode({"sessionId":"debug-session","runId":"pre-fix","hypothesisId":"A","location":"lib/core/services/api_service.dart:post","message":"ApiService.post returning 400 response for verification request","data":{"path":path,"statusCode":e.response?.statusCode},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n',
            mode: FileMode.append,
          );
        } catch (_) {}
        // #endregion
        return e.response!;
      }

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







