// Model untuk Medicine
class Medicine {
  final int? id;
  final String namaObat;
  final String dosis;
  final String catatan;

  Medicine({
    this.id,
    required this.namaObat,
    required this.dosis,
    required this.catatan,
  });

  // Convert JSON ke Medicine object
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      namaObat: json['nama_obat'],
      dosis: json['dosis'],
      catatan: json['catatan'],
    );
  }

  // Convert Medicine object ke JSON
  Map<String, dynamic> toJson() {
    return {
      'nama_obat': namaObat,
      'dosis': dosis,
      'catatan': catatan,
    };
  }
}

// Model untuk Schedule
class Schedule {
  final int? id;
  final int medicineId;
  final String namaObat;
  final String dosis;
  final String waktuMinum;
  final String status;
  final String tanggal;

  Schedule({
    this.id,
    required this.medicineId,
    required this.namaObat,
    required this.dosis,
    required this.waktuMinum,
    required this.status,
    required this.tanggal,
  });

  // Convert JSON ke Schedule object
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      medicineId: json['medicine_id'],
      namaObat: json['nama_obat'],
      dosis: json['dosis'],
      waktuMinum: json['waktu_minum'],
      status: json['status'],
      tanggal: json['tanggal'],
    );
  }

  // Convert Schedule object ke JSON
  Map<String, dynamic> toJson() {
    return {
      'medicine_id': medicineId,
      'nama_obat': namaObat,
      'dosis': dosis,
      'waktu_minum': waktuMinum,
      'status': status,
      'tanggal': tanggal,
    };
  }
}
