import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/incident_model.dart';

class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _setAuthHeader(String token) async {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  // Authentication
  Future<UserModel> register(String email, String password, String username) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'username': username,
      });

      return UserModel.fromMap(response.data);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];

      await _saveTokens(accessToken, refreshToken);
      await _setAuthHeader(accessToken);

      // Fetch user details
      final userResponse = await _dio.get('/auth/me');
      return UserModel.fromMap(userResponse.data).copyWith(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await _setAuthHeader(token);
        await _dio.post('/auth/logout');
      }
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _clearTokens();
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<String> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) throw Exception('No refresh token');

      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final accessToken = response.data['access_token'];
      await _storage.write(key: 'access_token', value: accessToken);
      await _setAuthHeader(accessToken);

      return accessToken;
    } catch (e) {
      await _clearTokens();
      throw Exception('Token refresh failed: $e');
    }
  }

  // Incident Reporting
  Future<String> reportIncident(
    IncidentModel incident,
    String videoPath,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      await _setAuthHeader(token);

      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(videoPath),
        'type': incident.type.name,
        'latitude': incident.latitude,
        'longitude': incident.longitude,
        'timestamp': incident.timestamp.toIso8601String(),
        if (incident.speed != null) 'speed': incident.speed,
        if (incident.heading != null) 'heading': incident.heading,
        if (incident.description != null) 'description': incident.description,
      });

      final response = await _dio.post('/incidents/report', data: formData);
      return response.data['incident_id'];
    } catch (e) {
      throw Exception('Failed to report incident: $e');
    }
  }

  Future<List<IncidentModel>> getNearbyIncidents(
    double latitude,
    double longitude, {
    double radius = AppConfig.nearbyIncidentRadiusKm,
    int timeWindow = AppConfig.incidentTimeWindowHours,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      await _setAuthHeader(token);

      final response = await _dio.get('/incidents/nearby', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'time_window': timeWindow,
      });

      final incidents = response.data['incidents'] as List;
      return incidents.map((i) => IncidentModel.fromMap(i)).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby incidents: $e');
    }
  }

  Future<IncidentModel> getIncident(String incidentId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      await _setAuthHeader(token);

      final response = await _dio.get('/incidents/$incidentId');
      return IncidentModel.fromMap(response.data);
    } catch (e) {
      throw Exception('Failed to fetch incident: $e');
    }
  }

  Future<void> deleteIncident(String incidentId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      await _setAuthHeader(token);

      await _dio.delete('/incidents/$incidentId');
    } catch (e) {
      throw Exception('Failed to delete incident: $e');
    }
  }

  Future<List<IncidentModel>> getMyIncidents() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      await _setAuthHeader(token);

      final response = await _dio.get('/users/me/incidents');
      final incidents = response.data as List;
      return incidents.map((i) => IncidentModel.fromMap(i)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user incidents: $e');
    }
  }
}
