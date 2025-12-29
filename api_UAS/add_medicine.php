<?php
/**
 * API Endpoint untuk Tambah Obat
 * Fungsi: Menerima dan menyimpan data obat baru ke database
 * Method: POST
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');
header('Access-Control-Max-Age: 86400');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

include 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

$user_id = $data['user_id'] ?? null;
$nama_obat = $data['nama_obat'] ?? '';
$dosis = $data['dosis'] ?? '';
$catatan = $data['catatan'] ?? '';

// Validasi input
if (empty($user_id)) {
    echo json_encode([
        'success' => false,
        'error' => 'User ID tidak boleh kosong'
    ]);
    exit;
}

if (empty($nama_obat)) {
    echo json_encode([
        'success' => false,
        'error' => 'Nama obat tidak boleh kosong'
    ]);
    exit;
}

if (empty($dosis)) {
    echo json_encode([
        'success' => false,
        'error' => 'Dosis tidak boleh kosong'
    ]);
    exit;
}

// Cek apakah user_id ada di tabel users
$check_user_sql = "SELECT id FROM users WHERE id = ?";
$check_user_stmt = $conn->prepare($check_user_sql);

if (!$check_user_stmt) {
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $conn->error
    ]);
    exit;
}

$check_user_stmt->bind_param('i', $user_id);
$check_user_stmt->execute();
$user_result = $check_user_stmt->get_result();

if ($user_result->num_rows === 0) {
    echo json_encode([
        'success' => false,
        'error' => 'User ID tidak ditemukan di database'
    ]);
    $check_user_stmt->close();
    exit;
}
$check_user_stmt->close();

$sql = "INSERT INTO medicines (user_id, nama_obat, dosis, catatan) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $conn->error
    ]);
    exit;
}

$stmt->bind_param('isss', $user_id, $nama_obat, $dosis, $catatan);

if ($stmt->execute()) {
    $medicine_id = $conn->insert_id;
    echo json_encode(['success' => true, 'medicine_id' => $medicine_id, 'message' => 'Obat berhasil ditambahkan']);
} else {
    echo json_encode(['success' => false, 'error' => 'Gagal menambahkan obat: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>