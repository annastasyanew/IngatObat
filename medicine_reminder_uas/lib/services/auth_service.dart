import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'http://localhost/api_UAS';

  // Register user baru
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          // Simpan user data ke local storage
          await _saveUserData(data['user']);
        }

        return data;
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      print('Error register: $e');
      return {'success': false, 'message': 'Koneksi gagal'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          // Simpan user data ke local storage
          await _saveUserData(data['user']);
        }

        return data;
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      print('Error login: $e');
      return {'success': false, 'message': 'Koneksi gagal'};
    }
  }

  // Simpan user data ke SharedPreferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userData['id']);
    await prefs.setString('user_name', userData['name']);
    await prefs.setString('user_email', userData['email']);
    if (userData['profile_picture'] != null) {
      await prefs.setString(
          'user_profile_picture', userData['profile_picture']);
    }
    await prefs.setBool('is_logged_in', true);
  }

  // Ambil user data dari SharedPreferences
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) return null;

    final userId = prefs.getInt('user_id');
    final userName = prefs.getString('user_name');
    final userEmail = prefs.getString('user_email');
    final profilePicture = prefs.getString('user_profile_picture');

    if (userId == null || userName == null || userEmail == null) return null;

    return User(
      id: userId,
      name: userName,
      email: userEmail,
      profilePicture: profilePicture,
    );
  }

  // Get user ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Check if user logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/edit_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': userId,
          'name': name,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          // Update local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', name);
          await prefs.setString('user_email', email);
        }

        return data;
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      print('Error updating profile: $e');
      return {'success': false, 'message': 'Koneksi gagal'};
    }
  }

  // Upload profile picture
  Future<Map<String, dynamic>> uploadProfilePicture({
    required int userId,
    required String imagePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_profile_picture.php'),
      );

      request.fields['id'] = userId.toString();
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          imagePath,
        ),
      );

      var response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data;
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      print('Error uploading picture: $e');
      return {'success': false, 'message': 'Koneksi gagal'};
    }
  }

  // Upload profile picture untuk Flutter Web
  Future<Map<String, dynamic>> uploadProfilePictureWeb({
    required int userId,
    required html.File file,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload_profile_picture.php'),
      );

      request.fields['id'] = userId.toString();

      // Read file sebagai bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoad.first;

      final bytes = (reader.result as List<int>);

      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_picture',
          bytes,
          filename: file.name,
          contentType: null, // Let the library determine it
        ),
      );

      print('=== Upload Request ===');
      print('URL: ${request.url}');
      print('Fields: ${request.fields}');
      print(
          'Files: ${request.files.map((f) => '${f.field} (${f.filename})').toList()}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('=== Upload Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      final result = jsonDecode(responseBody);

      // Update localStorage jika upload berhasil
      if (result['success'] == true && result['data'] != null) {
        final profilePicture = result['data']['profile_picture'];
        if (profilePicture != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile_picture', profilePicture);
        }
      }

      return result;
    } catch (e) {
      print('Error uploading picture (web): $e');
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // Request password reset
}
