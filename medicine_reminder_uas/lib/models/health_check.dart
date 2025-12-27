// Model untuk Health Check
class HealthCheck {
  final int? id;
  final int? userId;
  final String namaTes;
  final String catatan;
  final String tanggal;
  final String waktuPemeriksaan;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  HealthCheck({
    this.id,
    this.userId,
    required this.namaTes,
    required this.catatan,
    required this.tanggal,
    required this.waktuPemeriksaan,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // Convert JSON ke HealthCheck object
  factory HealthCheck.fromJson(Map<String, dynamic> json) {
    int? parsedUserId;
    if (json['user_id'] != null) {
      try {
        parsedUserId = int.parse(json['user_id'].toString());
      } catch (e) {
        parsedUserId = null;
      }
    }

    int? parsedId;
    if (json['id'] != null) {
      try {
        parsedId = int.parse(json['id'].toString());
      } catch (e) {
        parsedId = null;
      }
    }

    return HealthCheck(
      id: parsedId,
      userId: parsedUserId,
      namaTes: json['nama_tes']?.toString() ?? 'N/A',
      catatan: json['catatan']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      waktuPemeriksaan: json['waktu_pemeriksaan']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  // Convert HealthCheck object ke JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nama_tes': namaTes,
      'catatan': catatan,
      'tanggal': tanggal,
      'waktu_pemeriksaan': waktuPemeriksaan,
      'status': status,
    };
  }
}
