<?php
/**
 * API Endpoint untuk Edit/Update Jadwal Obat
 * Fungsi: Mengubah data jadwal minum obat yang sudah ada
 * Method: POST
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');

include 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

$schedule_id = $data['id'] ?? null;
$user_id = $data['user_id'] ?? null;
$status = $data['status'] ?? null;
$waktu_minum = $data['waktu_minum'] ?? null;

// Validasi input
if (empty($schedule_id) || empty($user_id)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Schedule ID dan User ID tidak boleh kosong'
    ]);
    exit;
}

// Cek apakah schedule milik user
$check_sql = "SELECT id FROM schedules WHERE id = ? AND user_id = ?";
$check_stmt = $conn->prepare($check_sql);

if (!$check_stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $conn->error
    ]);
    exit;
}

$check_stmt->bind_param('ii', $schedule_id, $user_id);
$check_stmt->execute();
$check_result = $check_stmt->get_result();

if ($check_result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'error' => 'Schedule tidak ditemukan atau Anda tidak memiliki akses'
    ]);
    $check_stmt->close();
    exit;
}
$check_stmt->close();

// Build query update
$update_fields = [];
$types = '';
$values = [];

if ($status !== null) {
    $update_fields[] = "status = ?";
    $types .= 's';
    $values[] = $status;
}

if ($waktu_minum !== null) {
    $update_fields[] = "waktu_minum = ?";
    $types .= 's';
    $values[] = $waktu_minum;
}

if (empty($update_fields)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Tidak ada data yang diubah'
    ]);
    exit;
}

$update_fields[] = "updated_at = NOW()";

$types .= 'ii';
$values[] = $schedule_id;
$values[] = $user_id;

$sql = "UPDATE schedules SET " . implode(', ', $update_fields) . " WHERE id = ? AND user_id = ?";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $conn->error
    ]);
    exit;
}

$stmt->bind_param($types, ...$values);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Jadwal obat berhasil diperbarui'
        ]);
    } else {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'Jadwal obat tidak ditemukan'
        ]);
    }
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Gagal memperbarui jadwal obat: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
