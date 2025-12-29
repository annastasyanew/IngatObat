import 'package:flutter/material.dart';
import '../../models/health_check.dart';
import '../../services/api_service.dart';
import '../../utils/date_formatter.dart';

class AddHealthCheckScreen extends StatefulWidget {
  const AddHealthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AddHealthCheckScreen> createState() => _AddHealthCheckScreenState();
}

class _AddHealthCheckScreenState extends State<AddHealthCheckScreen> {
  late ApiService _apiService;
  late TextEditingController _namaController;
  late TextEditingController _catatanController;
  late TextEditingController _tanggalController;
  late TextEditingController _waktuController;
  String _selectedStatus = 'Belum Selesai';
  bool _isLoading = false;

  final List<String> _statusOptions = ['Belum Selesai', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _namaController = TextEditingController();
    _catatanController = TextEditingController();
    _tanggalController = TextEditingController();
    _waktuController = TextEditingController();

    // Set default date to today
    _tanggalController.text = DateFormatter.formatDateOnly(DateTime.now());
    // Set default time to current time
    _waktuController.text = DateFormatter.formatTimeOnly(DateTime.now());
  }

  @override
  void dispose() {
    _namaController.dispose();
    _catatanController.dispose();
    _tanggalController.dispose();
    _waktuController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _tanggalController.text = DateFormatter.formatDateOnly(picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _waktuController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _addHealthCheck() async {
    if (_namaController.text.isEmpty ||
        _catatanController.text.isEmpty ||
        _tanggalController.text.isEmpty ||
        _waktuController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Convert status display text to database value (N or Y)
    final statusValue = _selectedStatus == 'Selesai' ? 'Y' : 'N';

    final healthCheck = HealthCheck(
      userId: 0, // Will be set by API service
      namaTes: _namaController.text,
      catatan: _catatanController.text,
      tanggal: _tanggalController.text,
      waktuPemeriksaan: _waktuController.text,
      status: statusValue,
    );

    final result = await _apiService.addHealthCheck(healthCheck);

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pemeriksaan kesehatan berhasil ditambahkan')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Gagal menambahkan pemeriksaan kesehatan. Periksa koneksi internet atau API server.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pemeriksaan Kesehatan'),
        backgroundColor: const Color(0xFF5DA9E9),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nama Tes
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                labelText: 'Nama Tes',
                hintText: 'Contoh: Pemeriksaan Darah, Tekanan Darah',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.health_and_safety),
              ),
            ),
            const SizedBox(height: 16),

            // Catatan
            TextField(
              controller: _catatanController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Catatan',
                hintText: 'Masukkan catatan atau hasil pemeriksaan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 16),

            // Tanggal
            GestureDetector(
              onTap: () => _selectDate(context),
              child: TextField(
                controller: _tanggalController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Tanggal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Waktu Pemeriksaan
            GestureDetector(
              onTap: () => _selectTime(context),
              child: TextField(
                controller: _waktuController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Waktu Pemeriksaan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.flag),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Tombol Submit
            ElevatedButton(
              onPressed: _isLoading ? null : _addHealthCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5DA9E9),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Simpan Pemeriksaan',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
