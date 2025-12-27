import 'package:flutter/material.dart';
import '../../models/health_check.dart';
import '../../services/api_service.dart';
import '../../utils/date_formatter.dart';

class EditHealthCheckScreen extends StatefulWidget {
  final HealthCheck healthCheck;

  const EditHealthCheckScreen({
    Key? key,
    required this.healthCheck,
  }) : super(key: key);

  @override
  State<EditHealthCheckScreen> createState() => _EditHealthCheckScreenState();
}

class _EditHealthCheckScreenState extends State<EditHealthCheckScreen> {
  late ApiService _apiService;
  late TextEditingController _namaController;
  late TextEditingController _catatanController;
  late TextEditingController _tanggalController;
  late TextEditingController _waktuController;
  late String _selectedStatus;
  bool _isLoading = false;

  final List<Map<String, String>> _statusOptions = [
    {'label': 'Belum Selesai', 'value': 'N'},
    {'label': 'Sudah Selesai', 'value': 'Y'},
  ];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _namaController = TextEditingController(text: widget.healthCheck.namaTes);
    _catatanController =
        TextEditingController(text: widget.healthCheck.catatan);
    _tanggalController =
        TextEditingController(text: widget.healthCheck.tanggal);
    _waktuController =
        TextEditingController(text: widget.healthCheck.waktuPemeriksaan);
    // Normalize status: jika 'Selesai' atau 'Y', gunakan 'Y', selainnya gunakan 'N'
    _selectedStatus = (widget.healthCheck.status == 'Selesai' ||
            widget.healthCheck.status == 'Y')
        ? 'Y'
        : 'N';
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
      initialDate: DateTime.parse(_tanggalController.text),
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
      initialTime: TimeOfDay(
        hour: int.parse(_waktuController.text.split(':')[0]),
        minute: int.parse(_waktuController.text.split(':')[1]),
      ),
    );
    if (picked != null) {
      _waktuController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _updateHealthCheck() async {
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

    final healthCheck = HealthCheck(
      id: widget.healthCheck.id,
      userId: widget.healthCheck.userId,
      namaTes: _namaController.text,
      catatan: _catatanController.text,
      tanggal: _tanggalController.text,
      waktuPemeriksaan: _waktuController.text,
      status: _selectedStatus,
    );

    final result = await _apiService.updateHealthCheck(healthCheck);

    setState(() {
      _isLoading = false;
    });

    if (result) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pemeriksaan kesehatan berhasil diperbarui')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal memperbarui pemeriksaan kesehatan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pemeriksaan Kesehatan'),
        backgroundColor: Colors.purple,
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
              items: _statusOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value']!,
                  child: Text(option['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Tombol Update
            ElevatedButton(
              onPressed: _isLoading ? null : _updateHealthCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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
                      'Perbarui Pemeriksaan',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
