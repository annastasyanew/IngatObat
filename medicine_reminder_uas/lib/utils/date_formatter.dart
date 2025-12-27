/// Helper untuk format date tanpa dependency pada Intl locale initialization
class DateFormatter {
  // Format date sebagai yyyy-MM-dd
  static String formatDateOnly(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // Format time sebagai HH:mm
  static String formatTimeOnly(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Format date sebagai "d MMM" (e.g., "6 Des")
  static String formatDayMonth(DateTime date) {
    const monthsShort = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${monthsShort[date.month - 1]}';
  }

  // Format date sebagai "6 Desember 2025" (Indonesia)
  static String formatDateFull(DateTime date) {
    const monthsFull = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${monthsFull[date.month - 1]} ${date.year}';
  }

  // Format date sebagai "Desember 2025" (Indonesia)
  static String formatMonthYear(DateTime date) {
    const monthsFull = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${monthsFull[date.month - 1]} ${date.year}';
  }
}
