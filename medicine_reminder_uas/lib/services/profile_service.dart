import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl = 'http://localhost/api_UAS';

  /// Get profile picture URL with cache busting
  static String getProfilePictureUrl(int userId) {
    // Add timestamp to bypass image cache
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hostname = html.window.location.hostname ?? 'localhost';
    return 'http://$hostname/api_UAS/get_profile_picture.php?id=$userId&t=$timestamp';
  }

  /// Upload profile picture untuk Flutter Web
  static Future<Map<String, dynamic>> uploadProfilePicture(
    int userId,
    html.File file,
  ) async {
    try {
      // Gunakan hostname dari window.location, bukan origin (karena origin include port dev)
      final hostname = html.window.location.hostname ?? 'localhost';
      final apiUrl = 'http://$hostname/api_UAS/upload_profile_picture.php';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(apiUrl),
      );

      // Tambah headers untuk CORS dan authentication jika perlu
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Tambah user ID
      request.fields['id'] = userId.toString();

      // Read file sebagai bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      // Tunggu file selesai dibaca
      await reader.onLoad.first;

      // Ambil bytes dari result
      final bytes = (reader.result as List<int>);

      print('=== Profile Picture Upload ===');
      print('User ID: $userId');
      print('File Name: ${file.name}');
      print('File Size: ${file.size} bytes');
      print('File Type: ${file.type}');
      print('Bytes Length: ${bytes.length}');

      // Detect MIME type dari filename atau file.type
      String mimeType = file.type;
      if (mimeType.isEmpty || mimeType == 'application/octet-stream') {
        // Fallback ke detection dari filename
        final ext = file.name.toLowerCase().split('.').last;
        mimeType = _getMimeType(ext);
      }
      print('MIME Type (final): $mimeType');

      // Tambah file ke request dengan content type yang proper
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_picture',
          bytes,
          filename: file.name,
          contentType: http.MediaType.parse(mimeType),
        ),
      );

      // Send request
      print('Sending request to: ${request.url}');
      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload timeout setelah 30 detik');
        },
      );

      final responseBody = await response.stream.bytesToString();

      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');

      // Check status code
      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode} - $responseBody',
        };
      }

      // Parse response
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

      return jsonResponse;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Get MIME type dari file extension
  static String _getMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Buka file picker untuk memilih foto
  static void openFilePicker(Function(html.File) onFilePicked) {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          print(
              'File selected: ${file.name} (${file.size} bytes, ${file.type})');
          onFilePicked(file);
        }
      });
    } catch (e) {
      print('Error opening file picker: $e');
    }
  }
}
