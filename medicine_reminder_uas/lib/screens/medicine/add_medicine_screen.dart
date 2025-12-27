import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/date_formatter.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({Key? key}) : super(key: key);

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  final TextEditingController _namaObatController = TextEditingController();
  final TextEditingController _dosisController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  final List<TimeOfDay> _selectedTimes = [];
  bool _isSaving = false;

  // Recurrence state
  String _recurrenceType = 'once'; // 'once', 'daily', 'weekly'
  List<String> _selectedDays = []; // Untuk weekly: Senin, Selasa, dst
  int _recurrenceDays = 7; // Berapa hari perulangan

  final List<String> _daysOfWeek = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  @override
  void dispose() {
    _namaObatController.dispose();
    _dosisController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  // Pilih waktu untuk minum obat
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTimes.add(picked);
      });
    }
  }

  // Hapus waktu yang sudah dipilih
  void _removeTime(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  // Format TimeOfDay ke string HH:mm:ss
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  // Build UI untuk pemilihan hari (untuk mingguan)
  Widget _buildDaySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_daysOfWeek.length, (index) {
        final day = _daysOfWeek[index];
        final isSelected = _selectedDays.contains(day);
        return FilterChip(
          label: Text(day),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
          },
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFF5DA9E9).withOpacity(0.3),
          side: BorderSide(
            color:
                isSelected ? const Color(0xFF5DA9E9) : const Color(0xFFDEEEF7),
          ),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF5DA9E9) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }),
    );
  }

  // Simpan data obat dan jadwal dengan recurrence
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 waktu minum obat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validasi recurrence
    if (_recurrenceType == 'weekly' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 hari untuk perulangan mingguan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // 1. Simpan data obat
    final medicine = Medicine(
      namaObat: _namaObatController.text,
      dosis: _dosisController.text,
      catatan: _catatanController.text,
    );

    final medicineId = await _apiService.addMedicine(medicine);

    if (medicineId == null) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan data obat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Simpan jadwal untuk setiap waktu dengan recurrence
    final today = DateTime.now();
    final String tanggalMulai = DateFormatter.formatDateOnly(today);

    print('=== ADDING SCHEDULES ===');
    print('📅 Today: $tanggalMulai');
    print('🔄 Recurrence Type: $_recurrenceType');
    if (_selectedDays.isNotEmpty) {
      print('📆 Selected Days: ${_selectedDays.join(", ")}');
    }
    print(
        '⏰ Times: ${_selectedTimes.map((t) => t.format(context)).join(", ")}');
    print('=======================');

    bool allSuccess = true;
    int totalJadwalDibuat = 0;

    for (var time in _selectedTimes) {
      final String waktuMinum = _formatTime(time);

      // Prepare repeat days jika weekly
      String? repeatDays;
      if (_recurrenceType == 'weekly') {
        // Convert hari Indonesia ke index (0 = Senin, 6 = Minggu)
        List<int> dayIndices = [];
        for (final day in _selectedDays) {
          dayIndices.add(_daysOfWeek.indexOf(day));
        }
        dayIndices.sort();
        repeatDays = dayIndices.join(',');
      }

      print(
          '📤 Sending: medicineId=$medicineId, time=$waktuMinum, repeatType=$_recurrenceType, repeatDays=$repeatDays');

      // Call API untuk add schedule dengan repeat
      final response = await _apiService.addScheduleRepeat(
        medicineId: medicineId,
        waktuMinum: waktuMinum,
        tanggalMulai: tanggalMulai,
        repeatType: _recurrenceType,
        jumlahHari: _recurrenceType == 'once' ? null : _recurrenceDays,
        repeatDays: repeatDays,
      );

      print('📥 Response for time $waktuMinum: $response');

      if (response['success'] == true) {
        final jadwalCount = response['jadwal_dibuat'] ?? 1;
        totalJadwalDibuat += (jadwalCount as int);
        print('✅ Success! Added $jadwalCount schedules');

        // Log tanggal schedule yang created
        if (response['first_schedule_date'] != null) {
          print('📍 First schedule date: ${response['first_schedule_date']}');
        }
      } else {
        print(
            '❌ Error adding schedule: ${response['error'] ?? 'Unknown error'}');
        allSuccess = false;
      }

      // Set notifikasi untuk waktu tersebut (jika belum lewat)
      final scheduledDateTime = DateTime(
        today.year,
        today.month,
        today.day,
        time.hour,
        time.minute,
      );

      if (scheduledDateTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: scheduledDateTime.millisecondsSinceEpoch ~/ 1000,
          title: 'Waktunya Minum Obat! 💊',
          body: '${_namaObatController.text} - ${_dosisController.text}',
          scheduledTime: scheduledDateTime,
        );
      }
    }

    setState(() {
      _isSaving = false;
    });

    print('=== SAVE RESULT ===');
    print('All Success: $allSuccess');
    print('Total Jadwal Dibuat: $totalJadwalDibuat');
    print('========================');

    if (allSuccess && totalJadwalDibuat > 0) {
      // Informasi tentang kapan jadwal dimulai dan waktu-waktu
      String scheduleInfo = '';
      String timeInfo = '';

      // Informasi waktu
      if (_selectedTimes.isNotEmpty) {
        final timeList = _selectedTimes.map((t) => t.format(context)).toList();
        timeInfo = 'Waktu: ${timeList.join(", ")}\n';
      }

      // Informasi hari/perulangan
      if (_recurrenceType == 'once') {
        scheduleInfo = 'Jadwal akan muncul hari ini';
      } else if (_recurrenceType == 'weekly') {
        scheduleInfo = 'Jadwal akan muncul setiap: ${_selectedDays.join(", ")}';
      } else if (_recurrenceType == 'daily') {
        scheduleInfo =
            'Jadwal akan muncul setiap hari selama $_recurrenceDays hari';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Obat berhasil ditambahkan dengan $totalJadwalDibuat jadwal\n'
              '$timeInfo'
              '$scheduleInfo',
              style: const TextStyle(fontSize: 14, height: 1.5)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ Beberapa jadwal gagal disimpan (${totalJadwalDibuat} berhasil)'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tambah Obat Baru',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5DA9E9),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card untuk informasi obat
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Obat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5DA9E9),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Obat
                    TextFormField(
                      controller: _namaObatController,
                      decoration: InputDecoration(
                        labelText: 'Nama Obat',
                        prefixIcon: const Icon(Icons.medication,
                            color: Color(0xFF5DA9E9)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEEEF7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEEEF7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF5DA9E9), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAF5FF),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama obat harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dosis
                    TextFormField(
                      controller: _dosisController,
                      decoration: InputDecoration(
                        labelText: 'Dosis (contoh: 1 tablet, 5ml)',
                        prefixIcon: const Icon(Icons.medical_services,
                            color: Color(0xFF5DA9E9)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEEEF7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEEEF7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF5DA9E9), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAF5FF),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Dosis harus diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Catatan
                    TextFormField(
                      controller: _catatanController,
                      decoration: InputDecoration(
                        labelText: 'Catatan (opsional)',
                        prefixIcon:
                            const Icon(Icons.note, color: Color(0xFF5DA9E9)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEEEF7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFDEEEF7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF5DA9E9), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAF5FF),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card untuk waktu minum
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Waktu Minum Obat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5DA9E9),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectTime,
                          icon: const Icon(Icons.access_time, size: 18),
                          label: const Text('Tambah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5DA9E9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List waktu yang sudah dipilih
                    if (_selectedTimes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDEEEF7)),
                        ),
                        child: const Center(
                          child: Text(
                            'Belum ada waktu dipilih\nTekan "Tambah" untuk menambahkan',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_selectedTimes.length, (index) {
                        final time = _selectedTimes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF5DA9E9).withOpacity(0.1),
                                const Color(0xFF5DA9E9).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFDEEEF7),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.alarm,
                                    color: Color(0xFF5DA9E9),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    time.format(context),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5DA9E9),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _removeTime(index),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card untuk perulangan jadwal
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perulangan Jadwal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5DA9E9),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pilihan tipe perulangan
                    Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Sekali saja (hari ini)'),
                          subtitle:
                              const Text('Jadwal hanya berlaku untuk hari ini'),
                          value: 'once',
                          groupValue: _recurrenceType,
                          onChanged: (value) {
                            setState(() {
                              _recurrenceType = value!;
                            });
                          },
                          activeColor: const Color(0xFF5DA9E9),
                        ),
                        RadioListTile<String>(
                          title: const Text('Setiap Hari'),
                          subtitle: Text(
                              'Jadwal berlaku selama $_recurrenceDays hari'),
                          value: 'daily',
                          groupValue: _recurrenceType,
                          onChanged: (value) {
                            setState(() {
                              _recurrenceType = value!;
                            });
                          },
                          activeColor: const Color(0xFF5DA9E9),
                        ),
                        RadioListTile<String>(
                          title: const Text('Setiap Minggu'),
                          subtitle: const Text(
                              'Pilih hari-hari tertentu setiap minggu'),
                          value: 'weekly',
                          groupValue: _recurrenceType,
                          onChanged: (value) {
                            setState(() {
                              _recurrenceType = value!;
                              _selectedDays.clear(); // Clear previous selection
                            });
                          },
                          activeColor: const Color(0xFF5DA9E9),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Pilihan hari untuk weekly
                    if (_recurrenceType == 'weekly') ...[
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Pilih hari-hari:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5DA9E9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDaySelector(),
                    ],

                    // Field untuk daily duration
                    if (_recurrenceType == 'daily') ...[
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Durasi Perulangan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5DA9E9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 40,
                                  child: TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        _recurrenceDays =
                                            int.tryParse(value) ?? 7;
                                      });
                                    },
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '$_recurrenceDays hari',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Jumlah Jadwal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_recurrenceDays * _selectedTimes.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Preview untuk weekly
                    if (_recurrenceType == 'weekly' &&
                        _selectedDays.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDEEEF7)),
                        ),
                        child: Text(
                          'Preview: Jadwal akan diulang setiap minggu pada hari ${_selectedDays.join(", ")} selama 3 bulan (${_selectedDays.length * _selectedTimes.length} jadwal per minggu)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5DA9E9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF5DA9E9).withOpacity(0.4),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Obat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
