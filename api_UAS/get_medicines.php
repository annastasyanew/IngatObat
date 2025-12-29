<?php
/**
 * API Endpoint untuk Ambil Daftar Obat
 * Fungsi: Mengambil semua data obat dari database untuk user tertentu
 * Method: GET
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

include 'config.php';

$user_id = $_GET['user_id'] ?? null;

if (empty($user_id)) {
    echo json_encode([
        'success' => false,
        'message' => 'User ID diperlukan'
    ]);
    exit;
}

$sql = "SELECT * FROM medicines WHERE user_id = ? ORDER BY created_at DESC";
$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $user_id);
$stmt->execute();
$result = $stmt->get_result();

$medicines = [];
while ($row = $result->fetch_assoc()) {
    $medicines[] = $row;
}

echo json_encode(['success' => true, 'data' => $medicines]);

$stmt->close();
$conn->close();
