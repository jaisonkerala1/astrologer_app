import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static SharedPreferences? _prefs;
  static bool _initialized = false;

  Future<void> initialize() async {
    if (!_initialized) {
      try {
        _prefs = await SharedPreferences.getInstance();
        _initialized = true;
        print('StorageService: Initialized with SharedPreferences - TRUE PERSISTENCE NOW WORKS!');
        
        // Check if we have any login data
        final isLoggedIn = await getIsLoggedIn();
        final phoneNumber = await getPhoneNumber();
        print('StorageService: Found login state - isLoggedIn: $isLoggedIn, phone: $phoneNumber');
      } catch (e) {
        print('StorageService: Error initializing SharedPreferences: $e');
        _initialized = false;
      }
    }
  }

  // Generic methods
  Future<bool> setString(String key, String value) async {
    if (_prefs != null) {
      final result = await _prefs!.setString(key, value);
      print('StorageService: Set $key = $value');
      return result;
    }
    return false;
  }

  Future<String?> getString(String key) async {
    if (_prefs != null) {
      final value = _prefs!.getString(key);
      print('StorageService: Get $key = $value');
      return value;
    }
    return null;
  }

  Future<bool> setInt(String key, int value) async {
    if (_prefs != null) {
      return await _prefs!.setInt(key, value);
    }
    return false;
  }

  Future<int?> getInt(String key) async {
    if (_prefs != null) {
      return _prefs!.getInt(key);
    }
    return null;
  }

  Future<bool> setBool(String key, bool value) async {
    if (_prefs != null) {
      final result = await _prefs!.setBool(key, value);
      print('StorageService: Set $key = $value (PERSISTENT!)');
      return result;
    }
    return false;
  }

  Future<bool?> getBool(String key) async {
    if (_prefs != null) {
      final value = _prefs!.getBool(key);
      print('StorageService: Get $key = $value (FROM PERSISTENT STORAGE!)');
      return value;
    }
    return null;
  }

  Future<bool> setDouble(String key, double value) async {
    if (_prefs != null) {
      return await _prefs!.setDouble(key, value);
    }
    return false;
  }

  Future<double?> getDouble(String key) async {
    if (_prefs != null) {
      return _prefs!.getDouble(key);
    }
    return null;
  }

  Future<bool> setStringList(String key, List<String> value) async {
    if (_prefs != null) {
      return await _prefs!.setStringList(key, value);
    }
    return false;
  }

  Future<List<String>?> getStringList(String key) async {
    if (_prefs != null) {
      return _prefs!.getStringList(key);
    }
    return null;
  }

  Future<bool> remove(String key) async {
    if (_prefs != null) {
      final result = await _prefs!.remove(key);
      print('StorageService: Removed $key (FROM PERSISTENT STORAGE!)');
      return result;
    }
    return false;
  }

  Future<bool> clear() async {
    if (_prefs != null) {
      final result = await _prefs!.clear();
      print('StorageService: Cleared all data (FROM PERSISTENT STORAGE!)');
      return result;
    }
    return false;
  }

  // Specific methods for app data
  Future<bool> setAuthToken(String token) async {
    return await setString('auth_token', token);
  }

  Future<String?> getAuthToken() async {
    return await getString('auth_token');
  }

  Future<bool> setUserData(String userData) async {
    return await setString('user_data', userData);
  }

  Future<String?> getUserData() async {
    return await getString('user_data');
  }

  Future<bool> setIsLoggedIn(bool isLoggedIn) async {
    print('StorageService: Setting isLoggedIn to $isLoggedIn (WILL PERSIST ACROSS APP RESTARTS!)');
    return await setBool('is_logged_in', isLoggedIn);
  }

  Future<bool?> getIsLoggedIn() async {
    final result = await getBool('is_logged_in');
    print('StorageService: Getting isLoggedIn: $result (FROM PERSISTENT STORAGE!)');
    return result;
  }

  Future<bool> setPhoneNumber(String phone) async {
    return await setString('phone_number', phone);
  }

  Future<String?> getPhoneNumber() async {
    return await getString('phone_number');
  }

  // Clear all auth data
  Future<bool> clearAuthData() async {
    await remove('auth_token');
    await remove('user_data');
    await remove('is_logged_in');
    await remove('phone_number');
    return true;
  }
}