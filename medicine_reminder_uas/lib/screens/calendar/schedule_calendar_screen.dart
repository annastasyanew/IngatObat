import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../models/health_check.dart';
import '../../services/api_service.dart';
import '../../utils/date_formatter.dart';

class ScheduleCalendarScreen extends StatefulWidget {
  const ScheduleCalendarScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends State<ScheduleCalendarScreen> {
  final ApiService _apiService = ApiService();
  late DateTime _selectedDate;
  late DateTime _firstDayOfMonth;
  late DateTime _lastDayOfMonth;
  List<Schedule> _schedules = [];
  List<HealthCheck> _healthChecks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      print(
          '📅 Loading schedules for month: ${_selectedDate.month}/${_selectedDate.year}');

      // Load schedules for the entire month
      List<Schedule> allSchedules = [];
      final daysInMonth =
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

      // Fetch schedules for each day of the month
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(_selectedDate.year, _selectedDate.month, day);
        final dateStr = DateFormatter.formatDateOnly(date);

        try {
          final schedules = await _apiService.getSchedules(dateStr);
          allSchedules.addAll(schedules);
        } catch (e) {
          print('⚠️ Error loading schedules for $dateStr: $e');
        }
      }

      final healthChecks = await _apiService.getHealthChecks();

      setState(() {
        _schedules = allSchedules;
        _healthChecks = healthChecks;
        _isLoading = false;
      });

      print(
          '✅ Loaded ${allSchedules.length} schedules and ${healthChecks.length} health checks');
    } catch (e) {
      print('Error loading schedules: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getEventsForDate(DateTime date) {
    final events = <dynamic>[];

    // Filter medicines untuk tanggal ini
    for (var schedule in _schedules) {
      try {
        // Parse tanggal string ke DateTime (format: YYYY-MM-DD)
        final scheduleDate = DateTime.parse(schedule.tanggal);
        if (scheduleDate.year == date.year &&
            scheduleDate.month == date.month &&
            scheduleDate.day == date.day) {
          events.add(schedule);
        }
      } catch (e) {
        print('Error parsing schedule date: $e');
      }
    }

    // Filter health checks untuk tanggal ini
    for (var check in _healthChecks) {
      try {
        // Parse tanggal string ke DateTime (format: YYYY-MM-DD)
        final checkDate = DateTime.parse(check.tanggal);
        if (checkDate.year == date.year &&
            checkDate.month == date.month &&
            checkDate.day == date.day) {
          events.add(check);
        }
      } catch (e) {
        print('Error parsing health check date: $e');
      }
    }

    return events;
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      _firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      _lastDayOfMonth =
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    });
    _loadSchedules();
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      _firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      _lastDayOfMonth =
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    });
    _loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Jadwal & Kalender',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5DA9E9),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5DA9E9)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Calendar Header
                  Container(
                    color: const Color(0xFF5DA9E9),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Month Navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: _previousMonth,
                            ),
                            Text(
                              DateFormatter.formatMonthYear(_selectedDate),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward,
                                  color: Colors.white),
                              onPressed: _nextMonth,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Day headers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                                  .map((day) => Text(
                                        day,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ))
                                  .toList(),
                        ),
                        const SizedBox(height: 12),
                        // Calendar Grid
                        _buildCalendarGrid(),
                      ],
                    ),
                  ),
                  // Events for selected date
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal untuk ${DateFormatter.formatDateFull(_selectedDate)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildEventsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendarGrid() {
    final days = <Widget>[];

    // Empty cells untuk hari sebelum 1 bulan
    final firstWeekday = _firstDayOfMonth.weekday % 7;
    for (var i = 0; i < firstWeekday; i++) {
      days.add(const SizedBox());
    }

    // Cells untuk setiap hari di bulan ini
    for (var day = 1; day <= _lastDayOfMonth.day; day++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, day);
      final isSelected = date.day == _selectedDate.day &&
          date.month == _selectedDate.month &&
          date.year == _selectedDate.year;
      final hasEvents = _getEventsForDate(date).isNotEmpty;

      days.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border:
                  isSelected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF5DA9E9) : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (hasEvents)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: days,
    );
  }

  Widget _buildEventsList() {
    final events = _getEventsForDate(_selectedDate);

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Tidak ada jadwal untuk hari ini',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: events.map((event) {
        if (event is Schedule) {
          return _buildScheduleItem(event);
        } else if (event is HealthCheck) {
          return _buildHealthCheckItem(event);
        }
        return const SizedBox();
      }).toList(),
    );
  }

  Widget _buildScheduleItem(Schedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5DA9E9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medication,
              color: Color(0xFF5DA9E9),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Obat: ${schedule.namaObat}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Jam: ${schedule.waktuMinum}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCheckItem(HealthCheck check) {
    final isCompleted = check.status.toUpperCase() == 'Y';

    // Debug print untuk melihat status value
    print(
        '🩺 Health Check: ${check.namaTes}, Status: "${check.status}", isCompleted: $isCompleted');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),

          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Color(0xFF4ECDC4),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama tes kesehatan
                Text(
                  check.namaTes,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),

                // Jam pemeriksaan
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      check.waktuPemeriksaan,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                // Catatan / keterangan
                if (check.catatan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.notes, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          check.catatan,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
