import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_model.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _employeeKey = 'employee_data';

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.yarmouk-water.jo/v1',
  );

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String deviceUuid,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
        'device_uuid': deviceUuid,
      });

      if (response.statusCode == 200) {
        final data = response.data is Map
            ? (response.data['data'] ?? response.data)
            : response.data;
        return {
          'success': true,
          'token': data['access_token'] ?? data['token'],
          'employee': data['employee'],
        };
      }
      return {
        'success': false,
        'message': _errMessage(response.data) ?? 'فشل تسجيل الدخول',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _errMessage(e.response?.data) ?? 'خطأ في الاتصال بالخادم',
      };
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      final response = await _dio.post(
        '/auth/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'تم تغيير كلمة المرور',
        };
      }
      return {'success': false, 'message': _errMessage(response.data)};
    } on DioException catch (e) {
      return {'success': false, 'message': _errMessage(e.response?.data)};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    try {
      final token = await getToken();
      final response = await _dio.patch(
        '/employees/me',
        data: {'full_name': fullName, 'phone': phone},
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data is Map
            ? (response.data['data'] ?? response.data)
            : response.data;
        return {
          'success': true,
          'employee': data['employee'],
          'message': response.data['message'] ?? 'تم تحديث الملف الشخصي',
        };
      }
      return {'success': false, 'message': _errMessage(response.data)};
    } on DioException catch (e) {
      return {'success': false, 'message': _errMessage(e.response?.data)};
    }
  }

  String? _errMessage(dynamic data) {
    if (data is Map) {
      return (data['detail'] ?? data['message'] ?? 'حدث خطأ').toString();
    }
    return null;
  }

  Future<void> saveSession(String token, Employee employee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_employeeKey, jsonEncode(employee.toJson()));
  }

  Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final employeeJson = prefs.getString(_employeeKey);

    if (token != null && employeeJson != null) {
      return {
        'token': token,
        'employee': jsonDecode(employeeJson),
      };
    }
    return null;
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _dio.post('/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_employeeKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
