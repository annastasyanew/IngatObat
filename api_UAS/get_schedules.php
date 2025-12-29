<?php
/**
 * API Endpoint untuk Ambil Daftar Jadwal Obat
 * Fungsi: Mengambil jadwal minum obat untuk tanggal tertentu
 * Method: GET
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

include 'config.php';

$user_id = $_GET['user_id'] ?? null;
$tanggal = $_GET['tanggal'] ?? null;

if (!$user_id) {
    echo json_encode(['success' => false, 'error' => 'Missing user_id', 'data' => null]);
    exit;
}

$sql = "SELECT 
        id,
        medicine_id,
        nama_obat,
        dosis,
        waktu_minum,
        status,
        tanggal
    FROM schedules 
    WHERE user_id = ?";

$params = [$user_id];
$types = 'i';

if (!empty($tanggal)) {
    $sql .= " AND tanggal = ?";
    $params[] = $tanggal;
    $types .= 's';
}

$sql .= " ORDER BY waktu_minum ASC";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode(['success' => false, 'error' => 'Database error: ' . $conn->error, 'data' => null]);
    exit;
}

$stmt->bind_param($types, ...$params);
$stmt->execute();
$result = $stmt->get_result();

$schedules = [];
while ($row = $result->fetch_assoc()) {
    $schedules[] = $row;
}

echo json_encode([
    'success' => true,
    'data' => $schedules,
    'message' => 'Schedules retrieved successfully'
]);

$stmt->close();
$conn->close();
?>
