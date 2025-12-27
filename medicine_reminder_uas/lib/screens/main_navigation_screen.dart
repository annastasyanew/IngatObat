import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'medicine/medicine_list_screen.dart';
import 'calendar/schedule_calendar_screen.dart';
import 'health_check/health_check_list_screen.dart';
import 'profile/profile_settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // List of screens untuk setiap tab
  late final List<Widget> _screens = [
    const HomeScreen(),
    const MedicineListScreen(),
    const ScheduleCalendarScreen(),
    const HealthCheckListScreen(),
    const ProfileSettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Stack(
        children: [
          // Background dengan notch curve menggunakan CustomPaint
          CustomPaint(
            painter: NotchPainter(),
            child: Container(
              height: 75,
              color: Colors.transparent,
            ),
          ),
          // Navigation items
          SizedBox(
            height: 75,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home, 'Beranda'),
                _buildNavItem(1, Icons.medication, 'Obat'),
                SizedBox(width: 70, child: Container()),
                _buildNavItem(3, Icons.health_and_safety, 'Kesehatan'),
                _buildNavItem(4, Icons.person, 'Profil'),
              ],
            ),
          ),
          // Jadwal button di notch
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _onItemTapped(2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _selectedIndex == 2
                              ? const Color(0xFF5DA9E9)
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5DA9E9).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: _selectedIndex == 2
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jadwal',
                        style: TextStyle(
                          fontSize: 10,
                          color: _selectedIndex == 2
                              ? const Color(0xFF5DA9E9)
                              : Colors.grey.shade400,
                          fontWeight: _selectedIndex == 2
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF5DA9E9).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color:
                  isSelected ? const Color(0xFF5DA9E9) : Colors.grey.shade500,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color:
                  isSelected ? const Color(0xFF5DA9E9) : Colors.grey.shade500,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter untuk membuat notch curve di navigation bar
class NotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final double notchRadius = 28;
    final double notchCenterX = size.width / 2;
    final double notchCenterY = 0;

    // Mulai dari bottom left
    path.moveTo(0, size.height);

    // Garis ke atas kiri
    path.lineTo(0, notchRadius);

    // Kurva notch sisi kiri - cubic bezier untuk smooth curve
    path.cubicTo(
      0,
      notchRadius - 20,
      notchCenterX - 40,
      notchCenterY - 25,
      notchCenterX - notchRadius,
      notchCenterY - 25,
    );

    // Kurva notch bawah - arc untuk rounded bottom
    path.arcToPoint(
      Offset(notchCenterX + notchRadius, notchCenterY - 25),
      radius: const Radius.circular(28),
      clockwise: true,
    );

    // Kurva notch sisi kanan - cubic bezier untuk smooth curve
    path.cubicTo(
      notchCenterX + 40,
      notchCenterY - 25,
      size.width,
      notchRadius - 20,
      size.width,
      notchRadius,
    );

    // Garis ke bawah kanan
    path.lineTo(size.width, size.height);

    // Tutup path
    path.close();

    // Draw shadow
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5),
    );

    // Draw path
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(NotchPainter oldDelegate) => false;
}
