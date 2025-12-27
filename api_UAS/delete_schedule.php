<?php
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

$schedule_id = $data['id'] ?? null;
$user_id = $data['user_id'] ?? null;

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

// Delete schedule
$sql = "DELETE FROM schedules WHERE id = ? AND user_id = ?";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $conn->error
    ]);
    exit;
}

$stmt->bind_param('ii', $schedule_id, $user_id);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Jadwal obat berhasil dihapus'
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
        'error' => 'Gagal menghapus jadwal obat: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
