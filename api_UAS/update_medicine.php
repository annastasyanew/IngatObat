<?php
/**
 * API Endpoint untuk Edit/Update Obat
 * Fungsi: Mengubah data obat yang sudah ada di database
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

$id = $data['id'] ?? null;
$user_id = $data['user_id'] ?? null;
$nama_obat = $data['nama_obat'] ?? null;
$dosis = $data['dosis'] ?? null;
$catatan = $data['catatan'] ?? null;

// Validasi input
if (empty($id) || empty($user_id)) {
    echo json_encode([
        'success' => false,
        'error' => 'Medicine ID dan User ID tidak boleh kosong'
    ]);
    exit;
}

// Cek apakah medicine milik user
$check_sql = "SELECT id FROM medicines WHERE id = ? AND user_id = ?";
$check_stmt = $conn->prepare($check_sql);

if (!$check_stmt) {
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $conn->error
    ]);
    exit;
}

$check_stmt->bind_param('ii', $id, $user_id);
$check_stmt->execute();
$check_result = $check_stmt->get_result();

if ($check_result->num_rows === 0) {
    echo json_encode([
        'success' => false,
        'error' => 'Medicine tidak ditemukan atau Anda tidak memiliki akses'
    ]);
    $check_stmt->close();
    exit;
}
$check_stmt->close();

// Build query update
$update_fields = [];
$types = '';
$values = [];

if ($nama_obat !== null) {
    $update_fields[] = "nama_obat = ?";
    $types .= 's';
    $values[] = $nama_obat;
}

if ($dosis !== null) {
    $update_fields[] = "dosis = ?";
    $types .= 's';
    $values[] = $dosis;
}

if ($catatan !== null) {
    $update_fields[] = "catatan = ?";
    $types .= 's';
    $values[] = $catatan;
}

if (empty($update_fields)) {
    echo json_encode([
        'success' => false,
        'error' => 'Tidak ada data yang diubah'
    ]);
    exit;
}

$update_fields[] = "updated_at = NOW()";

$types .= 'ii';
$values[] = $id;
$values[] = $user_id;

$sql = "UPDATE medicines SET " . implode(', ', $update_fields) . " WHERE id = ? AND user_id = ?";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $conn->error
    ]);
    exit;
}

$stmt->bind_param($types, ...$values);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Medicine berhasil diperbarui'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'error' => 'Gagal memperbarui medicine: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
