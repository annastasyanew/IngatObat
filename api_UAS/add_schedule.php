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

$user_id = $data['user_id'] ?? null;
$medicine_id = $data['medicine_id'] ?? null;
$waktu_minum = $data['waktu_minum'] ?? null;
$tanggal = $data['tanggal'] ?? date('Y-m-d');
$status = $data['status'] ?? 'belum';

// Validasi input
if (empty($user_id)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'User ID tidak boleh kosong'
    ]);
    exit;
}

if (empty($medicine_id)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Medicine ID tidak boleh kosong'
    ]);
    exit;
}

if (empty($waktu_minum)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Waktu minum tidak boleh kosong'
    ]);
    exit;
}

// Cek apakah medicine ada dan milik user
$check_sql = "SELECT id, nama_obat, dosis FROM medicines WHERE id = ? AND user_id = ?";
$check_stmt = $conn->prepare($check_sql);

if (!$check_stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $conn->error
    ]);
    exit;
}

$check_stmt->bind_param('ii', $medicine_id, $user_id);
$check_stmt->execute();
$check_result = $check_stmt->get_result();

if ($check_result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        'success' => false,
        'error' => 'Medicine tidak ditemukan atau Anda tidak memiliki akses'
    ]);
    $check_stmt->close();
    exit;
}

$medicine = $check_result->fetch_assoc();
$check_stmt->close();

// Insert ke schedules
$sql = "INSERT INTO schedules (user_id, medicine_id, nama_obat, dosis, waktu_minum, tanggal, status) 
        VALUES (?, ?, ?, ?, ?, ?, ?)";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $conn->error
    ]);
    exit;
}

$stmt->bind_param('iisssss', $user_id, $medicine_id, $medicine['nama_obat'], $medicine['dosis'], $waktu_minum, $tanggal, $status);

if ($stmt->execute()) {
    $schedule_id = $conn->insert_id;
    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Jadwal obat berhasil ditambahkan',
        'schedule_id' => $schedule_id,
        'schedule' => [
            'id' => $schedule_id,
            'user_id' => $user_id,
            'medicine_id' => $medicine_id,
            'nama_obat' => $medicine['nama_obat'],
            'dosis' => $medicine['dosis'],
            'waktu_minum' => $waktu_minum,
            'tanggal' => $tanggal,
            'status' => $status
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Gagal menambahkan jadwal obat: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
