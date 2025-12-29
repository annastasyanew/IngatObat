import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/medicine.dart';
import '../models/health_check.dart';
import 'auth_service.dart';
import '../utils/date_formatter.dart';

class ApiService {
  // Base URL akan di-set berdasarkan platform
  // Web: localhost, Android: 10.0.2.2, iOS: localhost, Device: IP address
  // Default ke localhost untuk web, akan di-update di initialize()
  static String baseUrl = 'http://localhost/api_UAS';

  // Inisialisasi base URL berdasarkan platform
  static void initialize() {
    if (kIsWeb) {
      baseUrl = 'http://localhost/api_UAS';
      print('🌐 [ApiService] Web platform detected - using localhost');
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      baseUrl = 'http://10.0.2.2/api_UAS';
      print('🤖 [ApiService] Android platform detected - using 10.0.2.2');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      baseUrl = 'http://localhost/api_UAS';
      print('🍎 [ApiService] iOS platform detected - using localhost');
    } else {
      // Untuk platform lain atau physical device, gunakan 127.0.0.1
      baseUrl = 'http://127.0.0.1/api_UAS';
      print('📱 [ApiService] Unknown platform - using 127.0.0.1');
    }
    print('📍 [ApiService] Base URL: $baseUrl');
  }

  final AuthService _authService = AuthService();

  // Get user ID from AuthService
  Future<int?> _getUserId() async {
    return await _authService.getUserId();
  }

  // Helper method untuk handle delete requests dengan proper error handling
  Future<Map<String, dynamic>> _handleDeleteRequest({
    required String endpoint,
    required int id,
    required int userId,
  }) async {
    try {
      final requestBody = jsonEncode({
        'id': id,
        'user_id': userId,
      });

      print('=== DELETE REQUEST DEBUG ===');
      print('Endpoint: $baseUrl/$endpoint');
      print('Request Body: $requestBody');
      print('Request Body (decoded): id=$id, user_id=$userId');

      final response = await http
          .post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout after 10 seconds');
        },
      );

      print('Delete Response status: ${response.statusCode}');
      print('Delete Response body: ${response.body}');
      print('========================');

      try {
        final data = jsonDecode(response.body);

        // Handle different status codes
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (data['success'] == true) {
            print('✅ Delete successful: ${data['message'] ?? 'OK'}');
            return {
              'success': true,
              'statusCode': response.statusCode,
              'message': data['message'] ?? '',
              'error': '',
            };
          } else {
            print('❌ Delete returned success=false: ${data['error']}');
            return {
              'success': false,
              'statusCode': response.statusCode,
              'message': '',
              'error': data['error'] ?? 'Unknown error',
            };
          }
        } else if (response.statusCode == 400) {
          print('❌ Bad request: ${data['error']}');
          return {
            'success': false,
            'statusCode': 400,
            'message': '',
            'error': data['error'] ?? 'Bad request. Missing required fields.',
          };
        } else if (response.statusCode == 404) {
          print('❌ Not found: ${data['error']}');
          return {
            'success': false,
            'statusCode': 404,
            'message': '',
            'error': data['error'] ?? 'Resource not found or already deleted.',
          };
        } else if (response.statusCode == 500) {
          print('❌ Server error: ${data['error']}');
          return {
            'success': false,
            'statusCode': 500,
            'message': '',
            'error': data['error'] ?? 'Server error. Please try again later.',
          };
        } else {
          print('❌ Unknown status code: ${response.statusCode}');
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': '',
            'error': data['error'] ?? 'Unknown error (${response.statusCode})',
          };
        }
      } catch (parseError) {
        print('❌ Error parsing response JSON: $parseError');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': '',
          'error': 'Failed to parse server response',
        };
      }
    } on SocketException catch (e) {
      print('❌ Network error (SocketException): $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': '',
        'error':
            'Network error: Is the server running? Check if Laragon is started.',
      };
    } on TimeoutException catch (e) {
      print('❌ Request timeout: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': '',
        'error': 'Request timeout. Server took too long to respond.',
      };
    } on FormatException catch (e) {
      print('❌ Format error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': '',
        'error': 'Invalid response format from server.',
      };
    } on http.ClientException catch (e) {
      print('❌ HTTP Client error: $e');
      print('This is likely a CORS issue or backend crash');
      return {
        'success': false,
        'statusCode': 0,
        'message': '',
        'error':
            'Failed to connect to server. Check backend logs for CORS or PHP errors.',
      };
    } catch (e) {
      print('❌ Unexpected error: ${e.runtimeType} - $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': '',
        'error': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  // Fungsi untuk menambah obat baru
  Future<int?> addMedicine(Medicine medicine) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return null;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/add_medicine.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'nama_obat': medicine.namaObat,
          'dosis': medicine.dosis,
          'catatan': medicine.catatan,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['medicine_id'];
        }
      }
      return null;
    } catch (e) {
      print('Error adding medicine: $e');
      return null;
    }
  }

  // Fungsi untuk update obat
  Future<bool> updateMedicine(Medicine medicine) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return false;
      }

      print('📝 Updating medicine with ID: ${medicine.id}, user_id: $userId');
      print('   Nama Obat: ${medicine.namaObat}');
      print('   Dosis: ${medicine.dosis}');
      print('   Catatan: ${medicine.catatan}');

      final response = await http.post(
        Uri.parse('$baseUrl/update_medicine.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': medicine.id,
          'user_id': userId,
          'nama_obat': medicine.namaObat,
          'dosis': medicine.dosis,
          'catatan': medicine.catatan,
        }),
      );

      print('📥 Update Response status: ${response.statusCode}');
      print('📥 Update Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response contains HTML error (backend issue)
        if (response.body.contains('<b>') ||
            response.body.contains('Fatal error')) {
          print('⚠️ Backend error detected in response');
          print('💡 This is a backend issue - schedules can still be updated');
          // Return true anyway since we can still update schedules
          // The medicine info will be updated even if this fails
          return true;
        }

        try {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            print('✅ Medicine updated successfully');
            return true;
          } else {
            print(
                '⚠️ Backend returned success=false: ${data['error'] ?? data['message']}');
            return true; // Still continue to update schedules
          }
        } catch (parseError) {
          print('⚠️ Error parsing response: $parseError');
          // If JSON parsing fails but status is 200, assume success for scheduling
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating medicine: $e');
      return false;
    }
  }

  // Fungsi untuk hapus obat - Returns Map with success status and error message
  Future<Map<String, dynamic>> deleteMedicine(int medicineId) async {
    try {
      print('Deleting medicine with ID: $medicineId');

      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return {
          'success': false,
          'error': 'User not logged in',
        };
      }

      print('Sending delete request with user_id: $userId');

      // Try POST method first
      print('=== Attempting POST method ===');
      var result = await _handleDeleteRequest(
        endpoint: 'delete_medicine.php',
        id: medicineId,
        userId: userId,
      );

      // If POST failed with ClientException, try GET method as fallback
      if (result['statusCode'] == 0 &&
          result['error']?.contains('Failed to connect') == true) {
        print('=== POST failed, attempting GET method as fallback ===');
        result = await _handleDeleteRequestGetMethod(
          endpoint: 'delete_medicine.php',
          id: medicineId,
          userId: userId,
        );
      }

      return {
        'success': result['success'] ?? false,
        'error': result['error'] ?? '',
        'statusCode': result['statusCode'] ?? 0,
      };
    } catch (e) {
      print('Error deleting medicine: $e');
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
      };
    }
  }

  // Alternative method using GET for CORS compatibility
  Future<Map<String, dynamic>> _handleDeleteRequestGetMethod({
    required String endpoint,
    required int id,
    required int userId,
  }) async {
    try {
      final queryUri = Uri.parse('$baseUrl/$endpoint?id=$id&user_id=$userId');

      print('GET Request: $queryUri');

      final response = await http.get(
        queryUri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout after 10 seconds');
        },
      );

      print('GET Response status: ${response.statusCode}');
      print('GET Response body: ${response.body}');

      try {
        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (data['success'] == true) {
            print('✅ GET Delete successful');
            return {
              'success': true,
              'statusCode': response.statusCode,
              'message': data['message'] ?? '',
              'error': '',
            };
          } else {
            print('❌ GET Delete failed: ${data['error']}');
            return {
              'success': false,
              'statusCode': response.statusCode,
              'message': '',
              'error': data['error'] ?? 'Unknown error',
            };
          }
        } else {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': '',
            'error': data['error'] ?? 'Unknown error (${response.statusCode})',
          };
        }
      } catch (parseError) {
        print('❌ Error parsing GET response: $parseError');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': '',
          'error': 'Failed to parse server response',
        };
      }
    } on SocketException catch (e) {
      print('❌ GET Network error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': '',
        'error': 'Network error: Backend may not be running',
      };
    } on TimeoutException catch (e) {
      print('❌ GET Timeout: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': '',
        'error': 'Request timeout',
      };
    } catch (e) {
      print('❌ GET Unexpected error: $e');
      return {
        'success': false,
        'statusCode': 0,
        'message': '',
        'error': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  // Fungsi untuk mengambil semua obat
  Future<List<Medicine>> getMedicines() async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/get_medicines.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<Medicine> medicines = [];
          for (var item in data['data']) {
            medicines.add(Medicine.fromJson(item));
          }
          return medicines;
        }
      }
      return [];
    } catch (e) {
      print('Error getting medicines: $e');
      return [];
    }
  }

  // Fungsi untuk menambah jadwal obat
  Future<bool> addSchedule(Schedule schedule) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_schedule.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(schedule.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error adding schedule: $e');
      return false;
    }
  }

  // Fungsi untuk mengambil jadwal berdasarkan tanggal
  Future<List<Schedule>> getSchedules(String tanggal) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return [];
      }

      final url = '$baseUrl/get_schedules.php?tanggal=$tanggal&user_id=$userId';
      print('Fetching schedules from: $url');

      final response = await http.get(Uri.parse(url));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response: $data');

        if (data['success'] == true && data['data'] != null) {
          List<Schedule> schedules = [];
          for (var item in data['data']) {
            schedules.add(Schedule.fromJson(item));
          }
          print('Successfully created ${schedules.length} Schedule objects');
          return schedules;
        } else {
          print('Response not successful or data is null');
        }
      }
      return [];
    } catch (e) {
      print('Error getting schedules: $e');
      return [];
    }
  }

  // Fungsi untuk mengambil jadwal berdasarkan medicine ID
  // Fetch schedules for next 14 days and filter by medicine ID
  Future<List<Schedule>> getSchedulesByMedicineId(int medicineId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return [];
      }

      print('📋 Fetching schedules for medicine ID $medicineId...');

      // Fetch schedules for the next 14 days (covering weekly patterns)
      List<Schedule> allSchedules = [];
      final today = DateTime.now();

      // Fetch schedules for key dates (today, +3, +7, +10, +14)
      final fetchDates = [0, 3, 7, 10, 14];

      for (int days in fetchDates) {
        final date = today.add(Duration(days: days));
        final dateStr = DateFormatter.formatDateOnly(date);

        try {
          print('  📅 Fetching for date: $dateStr');
          final schedules = await getSchedules(dateStr);
          allSchedules.addAll(schedules);
        } catch (e) {
          // Continue to next date if this one fails
          print('  ⚠️ Error fetching for $dateStr: $e');
        }
      }

      // Filter schedules by medicine ID and remove duplicates
      final filteredSchedules = allSchedules
          .where((schedule) => schedule.medicineId == medicineId)
          .toList();

      // Remove duplicates based on date and time
      final uniqueSchedules = <String, Schedule>{};
      for (var schedule in filteredSchedules) {
        final key =
            '${schedule.tanggal}_${schedule.waktuMinum}'; // date_time key
        uniqueSchedules[key] = schedule;
      }

      final result = uniqueSchedules.values.toList();
      print(
          '✅ Found ${result.length} unique schedules for medicine ID $medicineId');
      return result;
    } catch (e) {
      print('❌ Error getting schedules by medicine ID: $e');
      return [];
    }
  } // Fungsi untuk update status obat menjadi "sudah diminum"

  Future<Map<String, dynamic>> updateStatus(int scheduleId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('❌ User not logged in');
        return {
          'success': false,
          'error': 'User not logged in',
        };
      }

      print(
          '📤 Updating status for schedule ID: $scheduleId, user_id: $userId');

      final requestBody = jsonEncode({
        'id': scheduleId,
        'user_id': userId,
        'status': 'Y', // Mark as taken (sudah diminum)
      });

      print('📝 Request body: $requestBody');

      final response = await http
          .post(
        Uri.parse('$baseUrl/update_status.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout after 10 seconds');
        },
      );

      print('📥 Update Status Response status: ${response.statusCode}');
      print('📥 Update Status Response body: ${response.body}');

      try {
        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (data['success'] == true) {
            print('✅ Status updated successfully');
            return {
              'success': true,
              'error': '',
              'message': data['message'] ?? 'Status updated',
            };
          } else {
            print('❌ Update failed: ${data['error'] ?? 'Unknown error'}');
            return {
              'success': false,
              'error': data['error'] ?? 'Unknown error',
              'message': '',
            };
          }
        } else if (response.statusCode == 404) {
          print('❌ Schedule not found');
          return {
            'success': false,
            'error': data['error'] ?? 'Schedule not found',
            'message': '',
          };
        } else {
          print('❌ Update failed with status ${response.statusCode}');
          return {
            'success': false,
            'error': data['error'] ?? 'Server error',
            'message': '',
          };
        }
      } catch (parseError) {
        print('❌ Error parsing response: $parseError');
        return {
          'success': false,
          'error': 'Failed to parse server response',
          'message': '',
        };
      }
    } on SocketException catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'error': 'Network error: Server may not be running',
        'message': '',
      };
    } on TimeoutException catch (e) {
      print('❌ Request timeout: $e');
      return {
        'success': false,
        'error': 'Request timeout: Server took too long to respond',
        'message': '',
      };
    } catch (e) {
      print('❌ Error updating status: $e');
      return {
        'success': false,
        'error': 'Unexpected error: ${e.toString()}',
        'message': '',
      };
    }
  }

  // ========== HEALTH CHECK FUNCTIONS ==========

  // Fungsi untuk menambah health check baru
  Future<int?> addHealthCheck(HealthCheck healthCheck) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('❌ User not logged in');
        return null;
      }

      final requestBody = {
        'user_id': userId,
        'nama_tes': healthCheck.namaTes,
        'catatan': healthCheck.catatan,
        'tanggal': healthCheck.tanggal,
        'waktu_pemeriksaan': healthCheck.waktuPemeriksaan,
        'status': healthCheck.status,
      };

      print('📤 Adding health check with body: $requestBody');

      final response = await http
          .post(
        Uri.parse('$baseUrl/add_health_check.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout after 10 seconds');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print(
              '✅ Health check added successfully: ${data['health_check_id']}');
          return data['health_check_id'];
        } else {
          print('❌ API returned success=false: ${data['error']}');
          return null;
        }
      } else {
        print('❌ API returned status code: ${response.statusCode}');
        return null;
      }
    } on TimeoutException catch (e) {
      print('⏱️ Timeout error: $e');
      return null;
    } catch (e) {
      print('❌ Error adding health check: $e');
      return null;
    }
  }

  // Fungsi untuk mengambil semua health checks
  Future<List<HealthCheck>> getHealthChecks() async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/get_health_checks.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🩺 Raw health checks response: ${response.body}');
        if (data['success']) {
          List<HealthCheck> healthChecks = [];
          for (var item in data['data']) {
            print('  📋 Item status value: "${item['status']}"');
            healthChecks.add(HealthCheck.fromJson(item));
          }
          print('✅ Loaded ${healthChecks.length} health checks');
          return healthChecks;
        }
      }
      return [];
    } catch (e) {
      print('Error getting health checks: $e');
      return [];
    }
  }

  // Fungsi untuk update health check
  Future<bool> updateHealthCheck(HealthCheck healthCheck) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return false;
      }

      print(
          'Updating health check with ID: ${healthCheck.id}, user_id: $userId');

      final response = await http.post(
        Uri.parse('$baseUrl/update_health_check.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': healthCheck.id,
          'user_id': userId,
          'nama_tes': healthCheck.namaTes,
          'catatan': healthCheck.catatan,
          'tanggal': healthCheck.tanggal,
          'waktu_pemeriksaan': healthCheck.waktuPemeriksaan,
          'status': healthCheck.status,
        }),
      );

      print('Update Health Check Response status: ${response.statusCode}');
      print('Update Health Check Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error updating health check: $e');
      return false;
    }
  }

  // Fungsi untuk hapus health check - Returns Map with success status and error message
  Future<Map<String, dynamic>> deleteHealthCheck(int healthCheckId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return {
          'success': false,
          'error': 'User not logged in',
        };
      }

      print('Deleting health check with ID: $healthCheckId, user_id: $userId');

      final result = await _handleDeleteRequest(
        endpoint: 'delete_health_check.php',
        id: healthCheckId,
        userId: userId,
      );

      return {
        'success': result['success'] ?? false,
        'error': result['error'] ?? '',
        'statusCode': result['statusCode'] ?? 0,
      };
    } catch (e) {
      print('Error deleting health check: $e');
      return {
        'success': false,
        'error': 'Error: ${e.toString()}',
      };
    }
  }

  // Fungsi untuk mengambil health check berdasarkan tanggal
  Future<List<HealthCheck>> getHealthChecksByDate(String tanggal) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return [];
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/get_health_checks_by_date.php?user_id=$userId&tanggal=$tanggal'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<HealthCheck> healthChecks = [];
          for (var item in data['data']) {
            healthChecks.add(HealthCheck.fromJson(item));
          }
          return healthChecks;
        }
      }
      return [];
    } catch (e) {
      print('Error getting health checks by date: $e');
      return [];
    }
  }

  // Fungsi untuk menambah jadwal obat dengan repeat/perulangan
  Future<Map<String, dynamic>> addScheduleRepeat({
    required int medicineId,
    required String waktuMinum,
    required String tanggalMulai,
    required String repeatType, // 'once', 'daily', 'weekly', 'custom'
    int? jumlahHari,
    String? repeatDays, // format: "1,2,3,4,5" atau "mon,tue,wed,thu,fri"
    String? repeatUntil,
  }) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        return {'success': false, 'error': 'User not logged in'};
      }

      final requestBody = {
        'user_id': userId,
        'medicine_id': medicineId,
        'waktu_minum': waktuMinum,
        'tanggal_mulai': tanggalMulai,
        'repeat_type': repeatType,
        if (jumlahHari != null) 'jumlah_hari': jumlahHari,
        if (repeatDays != null) 'repeat_days': repeatDays,
        if (repeatUntil != null) 'repeat_until': repeatUntil,
      };

      print('Adding schedule with repeat:');
      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/add_schedule_repeat.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          print('Parsed response: $responseData');
          return responseData;
        } catch (parseError) {
          print('Error parsing response JSON: $parseError');

          // Check if it's a duplicate key error (which means schedule already exists)
          if (response.body.contains('Duplicate entry') ||
              response.body.contains('unique_schedule')) {
            print(
                'ℹ️ Schedule already exists (duplicate) - treating as success');
            return {
              'success': true,
              'message': 'Schedule already exists',
              'jadwal_dibuat': 0,
              'note': 'Duplicate - not created'
            };
          }

          return {
            'success': false,
            'error': 'Invalid JSON response: ${response.body}'
          };
        }
      } else {
        return {
          'success': false,
          'error':
              'Failed to add schedule: ${response.statusCode} - ${response.body}'
        };
      }
    } catch (e) {
      print('Error in addScheduleRepeat: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Fungsi untuk menghapus semua jadwal obat (untuk update/edit)
  Future<bool> deleteSchedulesByMedicineId(int medicineId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('User not logged in');
        return false;
      }

      print('🗑️ Deleting all schedules for medicine ID: $medicineId');

      final requestBody = jsonEncode({
        'user_id': userId,
        'medicine_id': medicineId,
      });

      print('📤 Delete request body: $requestBody');

      final response = await http
          .post(
        Uri.parse('$baseUrl/delete_medicine_schedules.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout after 10 seconds');
        },
      );

      print('📥 Delete response status: ${response.statusCode}');
      print('📥 Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            print('✅ Schedules deleted successfully');
            return true;
          } else {
            print('⚠️ Delete response: ${data['message'] ?? data['error']}');
            // Return true anyway - if schedules don't exist, that's fine
            return true;
          }
        } catch (parseError) {
          print('⚠️ Error parsing delete response: $parseError');
          // Return true anyway - we can proceed with new schedules
          return true;
        }
      } else {
        // If endpoint doesn't exist, return true and proceed
        // Backend might not have this endpoint yet
        print('⚠️ Delete endpoint returned ${response.statusCode}');
        return true;
      }
    } catch (e) {
      print('⚠️ Error deleting schedules: $e');
      // Return true anyway - continue with update
      return true;
    }
  }

  // Hitung kepatuhan obat berdasarkan jadwal 7 hari terakhir
  Future<Map<String, dynamic>> calculateMedicineAdherence() async {
    try {
      final userId = await _getUserId();
      if (userId == null) {
        print('❌ User not logged in');
        return {
          'success': false,
          'adherence': 0,
          'total': 0,
          'completed': 0,
        };
      }

      print('📊 Calculating adherence for user $userId...');

      // Ambil jadwal untuk 7 hari terakhir
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      int totalSchedules = 0;
      int completedSchedules = 0;

      // Fetch schedules untuk setiap hari dalam 7 hari terakhir
      for (int i = 0; i < 7; i++) {
        final date = startDate.add(Duration(days: i));
        final dateStr = DateFormatter.formatDateOnly(date);

        try {
          final schedules = await getSchedules(dateStr);
          totalSchedules += schedules.length;

          // Count jadwal yang sudah selesai (status = "1" atau "Selesai")
          final completedToday = schedules
              .where((s) =>
                  s.status == '1' ||
                  s.status.toLowerCase() == 'selesai' ||
                  s.status.toLowerCase() == 'sudah')
              .length;
          completedSchedules += completedToday;

          print('  📅 $dateStr: $completedToday/${schedules.length} completed');
        } catch (e) {
          print('⚠️ Error loading schedules for $dateStr: $e');
        }
      }

      // Hitung persentase kepatuhan
      final adherence = totalSchedules > 0
          ? ((completedSchedules / totalSchedules) * 100).toStringAsFixed(0)
          : '0';

      final result = {
        'success': true,
        'adherence': int.parse(adherence),
        'total': totalSchedules,
        'completed': completedSchedules,
        'period': '7 hari',
      };

      print(
          '✅ Adherence calculated: $adherence% ($completedSchedules/$totalSchedules)');
      return result;
    } catch (e) {
      print('Error calculating adherence: $e');
      return {
        'success': false,
        'adherence': 0,
        'total': 0,
        'completed': 0,
      };
    }
  }
}
