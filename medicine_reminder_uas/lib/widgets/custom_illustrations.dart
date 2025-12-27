import 'package:flutter/material.dart';
import 'dart:math' as math;

// Ilustrasi untuk Health Check
class HealthCheckIllustration extends StatelessWidget {
  const HealthCheckIllustration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HealthCheckPainter(),
      size: const Size(200, 150),
    );
  }
}

class HealthCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Background circle
    paint.color = const Color(0xFFE8D5F2);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), 40, paint);

    // Plant decoration
    paint.color = const Color(0xFF4CAF50);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 8, paint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.75), 6, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.65), 7, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Ilustrasi untuk Reminders
class RemindersIllustration extends StatelessWidget {
  const RemindersIllustration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RemindersPainter(),
      size: const Size(200, 200),
    );
  }
}

class RemindersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Pills
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
    ];

    final positions = [
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.7, size.height * 0.5),
    ];

    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: positions[i],
            width: 20,
            height: 12,
          ),
          const Radius.circular(6),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Ilustrasi untuk Notification
class NotificationIllustration extends StatelessWidget {
  const NotificationIllustration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NotificationPainter(),
      size: const Size(200, 150),
    );
  }
}

class NotificationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Bell shape
    paint.color = const Color(0xFF5DA9E9);
    paint.style = PaintingStyle.fill;

    // Bell body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.5),
          width: 50,
          height: 60,
        ),
        const Radius.circular(15),
      ),
      paint,
    );

    // Bell clapper
    paint.color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.75), 6, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Ilustrasi untuk Medicine
class MedicineIllustration extends StatelessWidget {
  final Color color;

  const MedicineIllustration({
    Key? key,
    this.color = const Color(0xFF5DA9E9),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MedicinePainter(color),
      size: const Size(100, 100),
    );
  }
}

class MedicinePainter extends CustomPainter {
  final Color color;

  MedicinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Bottle body
    paint.color = color.withOpacity(0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.6),
          width: 30,
          height: 50,
        ),
        const Radius.circular(8),
      ),
      paint,
    );

    // Bottle cap
    paint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.25),
          width: 20,
          height: 15,
        ),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Ilustrasi untuk App Icon - Clock dengan Checkmark
class AppIconIllustration extends StatelessWidget {
  final double size;

  const AppIconIllustration({
    Key? key,
    this.size = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AppIconPainter(),
      size: Size(size, size),
    );
  }
}

class AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.35;

    // Draw main clock circle - filled
    final clockPaint = Paint()
      ..color = const Color(0xFF5DA9E9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), radius, clockPaint);

    // Draw clock border (darker blue)
    final borderPaint = Paint()
      ..color = const Color(0xFF4A90D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(Offset(centerX, centerY), radius, borderPaint);

    // Draw clock numbers dots
    final dotPaint = Paint()
      ..color = const Color(0xFF6EC1E4)
      ..style = PaintingStyle.fill;

    // 12 o'clock
    canvas.drawCircle(Offset(centerX, centerY - radius + 8), 3.5, dotPaint);
    // 3 o'clock
    canvas.drawCircle(Offset(centerX + radius - 8, centerY), 3.5, dotPaint);
    // 6 o'clock
    canvas.drawCircle(Offset(centerX, centerY + radius - 8), 3.5, dotPaint);
    // 9 o'clock
    canvas.drawCircle(Offset(centerX - radius + 8, centerY), 3.5, dotPaint);

    // Draw clock hands
    final handPaint = Paint()
      ..color = const Color(0xFF6EC1E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Hour hand (pointing to 10)
    final hourHandLength = radius * 0.5;
    final hourAngle = -0.7; // approximately 10 o'clock
    final hourX = centerX + hourHandLength * math.cos(hourAngle);
    final hourY = centerY + hourHandLength * math.sin(hourAngle);
    canvas.drawLine(Offset(centerX, centerY), Offset(hourX, hourY), handPaint);

    // Minute hand (pointing to 2)
    final minuteHandLength = radius * 0.65;
    final minuteAngle = 0.5; // approximately 2 o'clock
    final minuteX = centerX + minuteHandLength * math.cos(minuteAngle);
    final minuteY = centerY + minuteHandLength * math.sin(minuteAngle);
    canvas.drawLine(
        Offset(centerX, centerY), Offset(minuteX, minuteY), handPaint);

    // Draw center dot
    final centerDotPaint = Paint()
      ..color = const Color(0xFF6EC1E4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 2.5, centerDotPaint);

    // Draw medicine pill (checkmark area)
    final pillX = centerX + radius * 0.6;
    final pillY = centerY + radius * 0.5;
    final pillWidth = radius * 0.45;
    final pillHeight = radius * 0.35;

    // Pill background (light blue)
    final pillPaint = Paint()
      ..color = const Color(0xFF6EC1E4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pillX, pillY),
          width: pillWidth,
          height: pillHeight,
        ),
        const Radius.circular(10),
      ),
      pillPaint,
    );

    // Draw checkmark inside pill
    final checkmarkPaint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Checkmark path
    final checkPath = Path();
    checkPath.moveTo(pillX - pillWidth * 0.25, pillY + 2);
    checkPath.lineTo(pillX - pillWidth * 0.05, pillY + pillHeight * 0.25);
    checkPath.lineTo(pillX + pillWidth * 0.25, pillY - pillHeight * 0.2);

    canvas.drawPath(checkPath, checkmarkPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
