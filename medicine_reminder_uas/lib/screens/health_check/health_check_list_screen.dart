import 'package:flutter/material.dart';
import '../../models/health_check.dart';
import '../../services/api_service.dart';
import './add_health_check_screen.dart';
import './edit_health_check_screen.dart';

class HealthCheckListScreen extends StatefulWidget {
  const HealthCheckListScreen({Key? key}) : super(key: key);

  @override
  State<HealthCheckListScreen> createState() => _HealthCheckListScreenState();
}

class _HealthCheckListScreenState extends State<HealthCheckListScreen> {
  late ApiService _apiService;
  late Future<List<HealthCheck>> _healthChecks;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadHealthChecks();
  }

  void _loadHealthChecks() {
    setState(() {
      _healthChecks = _apiService.getHealthChecks();
    });
  }

  Future<void> _deleteHealthCheck(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pemeriksaan Kesehatan'),
        content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _apiService.deleteHealthCheck(id);
      if (result['success'] == true) {
        _loadHealthChecks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dihapus')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus data')),
        );
      }
    }
  }

  Future<void> _toggleHealthCheckStatus(HealthCheck check) async {
    // Toggle status: jika Selesai/Y menjadi Belum Selesai/N, dan sebaliknya
    final newStatus =
        (check.status == 'Selesai' || check.status == 'Y') ? 'N' : 'Y';

    final updatedCheck = HealthCheck(
      id: check.id,
      userId: check.userId,
      namaTes: check.namaTes,
      catatan: check.catatan,
      tanggal: check.tanggal,
      waktuPemeriksaan: check.waktuPemeriksaan,
      status: newStatus,
      createdAt: check.createdAt,
      updatedAt: check.updatedAt,
    );

    final success = await _apiService.updateHealthCheck(updatedCheck);
    if (success) {
      _loadHealthChecks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'Y'
              ? 'Pemeriksaan dikonfirmasi'
              : 'Status dikembalikan ke menunggu konfirmasi'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemeriksaan Kesehatan'),
        backgroundColor: const Color(0xFF5DA9E9),
        centerTitle: true,
      ),
      body: FutureBuilder<List<HealthCheck>>(
        future: _healthChecks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5DA9E9)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final healthChecks = snapshot.data ?? [];

          if (healthChecks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.health_and_safety,
                    size: 80,
                    color: const Color(0xFF5DA9E9).withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada data pemeriksaan kesehatan',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddHealthCheckScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadHealthChecks();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Pemeriksaan'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: healthChecks.length,
            itemBuilder: (context, index) {
              final check = healthChecks[index];
              final isConfirmed =
                  (check.status == 'Selesai' || check.status == 'Y');

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header dengan nama tes dan menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  check.namaTes,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  check.catatan,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('Edit'),
                                onTap: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditHealthCheckScreen(
                                              healthCheck: check),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadHealthChecks();
                                  }
                                },
                              ),
                              PopupMenuItem(
                                child: const Text('Hapus',
                                    style: TextStyle(color: Colors.red)),
                                onTap: () => _deleteHealthCheck(check.id!),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tanggal dan waktu
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '${check.tanggal} - ${check.waktuPemeriksaan}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status button yang bisa diklik
                      GestureDetector(
                        onTap: () => _toggleHealthCheckStatus(check),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isConfirmed
                                ? const Color(0xFFD4EDDA)
                                : const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isConfirmed
                                  ? const Color(0xFF28A745)
                                  : const Color(0xFFFFC107),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isConfirmed
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isConfirmed
                                    ? const Color(0xFF28A745)
                                    : const Color(0xFFFFC107),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isConfirmed
                                    ? 'Sudah Dikonfirmasi'
                                    : 'Tap untuk Konfirmasi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isConfirmed
                                      ? const Color(0xFF28A745)
                                      : const Color(0xFFFFC107),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddHealthCheckScreen(),
            ),
          );
          if (result == true) {
            _loadHealthChecks();
          }
        },
        backgroundColor: const Color(0xFF5DA9E9),
        child: const Icon(Icons.add),
      ),
    );
  }
}
