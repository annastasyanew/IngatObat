import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../screens/medicine/edit_medicine_screen.dart';

class MedicineCard extends StatefulWidget {
  final Schedule schedule;
  final VoidCallback onStatusChanged;

  const MedicineCard({
    Key? key,
    required this.schedule,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  bool _isUpdating = false;

  // Fungsi untuk menandai obat sudah diminum
  Future<void> _markAsTaken() async {
    setState(() {
      _isUpdating = true;
    });

    final result = await _apiService.updateStatus(widget.schedule.id!);

    if (!mounted) {
      setState(() {
        _isUpdating = false;
      });
      return;
    }

    if (result['success'] == true) {
      // Cancel notifikasi untuk jadwal ini
      await _notificationService.cancelNotification(widget.schedule.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Obat berhasil ditandai sudah diminum'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh tampilan
      widget.onStatusChanged();
    } else {
      final errorMessage = result['error'] ?? 'Gagal update status';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      _isUpdating = false;
    });
  }

  // Fungsi untuk edit obat
  Future<void> _editMedicine() async {
    // Buat object Medicine dari schedule
    final medicine = Medicine(
      id: widget.schedule.medicineId,
      namaObat: widget.schedule.namaObat,
      dosis: widget.schedule.dosis,
      catatan: '', // Catatan tidak ada di schedule, bisa dikosongkan
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMedicineScreen(medicine: medicine),
      ),
    );

    if (result == true) {
      // Add small delay to ensure database is updated
      await Future.delayed(const Duration(milliseconds: 500));

      print('🔄 Refreshing medicine data after edit');
      widget.onStatusChanged();
    }
  }

  // Fungsi untuk hapus obat
  Future<void> _deleteMedicine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Obat'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${widget.schedule.namaObat}"?\n\nSemua jadwal terkait akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result =
          await _apiService.deleteMedicine(widget.schedule.medicineId);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Obat berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStatusChanged();
      } else {
        final errorMessage = result['error'] ?? 'Gagal menghapus obat';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Ambil warna berdasarkan waktu - Calm Health Theme (High Contrast untuk orang tua)
  Color _getColorByTime(String waktu) {
    final hour = int.parse(waktu.split(':')[0]);

    if (hour >= 5 && hour < 12) {
      return const Color(0xFF6BCB77); // Pagi - Hijau lembut (segar, energi)
    } else if (hour >= 12 && hour < 17) {
      return const Color(0xFFF2994A); // Siang - Orange (aktif, terang)
    } else if (hour >= 17 && hour < 21) {
      return const Color(0xFFE67E22); // Sore - Oranye gelap (transisi, santai)
    } else {
      return const Color(0xFF5DA9E9); // Malam - Soft Blue (tenang, istirahat)
    }
  }

  // Ambil label waktu
  String _getTimeLabel(String waktu) {
    final hour = int.parse(waktu.split(':')[0]);

    if (hour >= 5 && hour < 12) {
      return 'Pagi';
    } else if (hour >= 12 && hour < 17) {
      return 'Siang';
    } else if (hour >= 17 && hour < 21) {
      return 'Sore';
    } else {
      return 'Malam';
    }
  }

  // Ambil icon berdasarkan waktu
  IconData _getIconByTime(String waktu) {
    final hour = int.parse(waktu.split(':')[0]);

    if (hour >= 5 && hour < 12) {
      return Icons.wb_sunny; // Pagi - Matahari
    } else if (hour >= 12 && hour < 17) {
      return Icons.cloud; // Siang - Awan
    } else if (hour >= 17 && hour < 21) {
      return Icons.wb_twilight; // Sore - Senja
    } else {
      return Icons.nights_stay; // Malam - Bulan
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTaken = widget.schedule.status == 'Y';
    final Color cardColor = _getColorByTime(widget.schedule.waktuMinum);
    final IconData timeIcon = _getIconByTime(widget.schedule.waktuMinum);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isTaken
                  ? [Colors.grey.shade200, Colors.grey.shade300]
                  : [cardColor.withOpacity(0.8), cardColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan waktu dan aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            timeIcon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.schedule.waktuMinum,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _getTimeLabel(widget.schedule.waktuMinum),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Tombol Edit & Hapus
                    if (!isTaken)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: Colors.white,
                            onPressed: _editMedicine,
                            tooltip: 'Edit Obat',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            color: Colors.white,
                            onPressed: _deleteMedicine,
                            tooltip: 'Hapus Obat',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Nama obat dan dosis
                Text(
                  widget.schedule.namaObat,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.medication,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.schedule.dosis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Status atau tombol
                if (isTaken)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Sudah Diminum',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _markAsTaken,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Sudah Minum Obat',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
