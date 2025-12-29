<?php
/**
 * API Endpoint untuk Tambah Health Check (Pemeriksaan Kesehatan)
 * Fungsi: Menerima dan menyimpan data pemeriksaan kesehatan user ke database
 * Method: POST
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    $data = json_decode(file_get_contents('php://input'), true);
    
    // Validate required fields
    $required_fields = ['user_id', 'nama_tes', 'catatan', 'tanggal', 'waktu_pemeriksaan', 'status'];
    
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || trim($data[$field]) === '') {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => "Field '$field' diperlukan"
            ]);
            exit;
        }
    }
    
    include 'config.php';
    
    // Get values
    $user_id = intval($data['user_id']);
    $nama_tes = trim($data['nama_tes']);
    $catatan = trim($data['catatan']);
    $tanggal = trim($data['tanggal']);
    $waktu_pemeriksaan = trim($data['waktu_pemeriksaan']);
    $status = trim($data['status']);
    
    // Normalize status: convert to Y or N only
    $status_lower = strtolower($status);
    if ($status_lower === 'y' || $status_lower === 'selesai' || $status_lower === 'sudah' || $status_lower === 'yes' || $status_lower === 'true' || $status === '1') {
        $status = 'Y';
    } else {
        $status = 'N';
    }
    
    // Validate user_id
    if ($user_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'User ID tidak valid'
        ]);
        exit;
    }
    
    // IMPORTANT: Verify user exists
    $user_check = $conn->prepare("SELECT id FROM users WHERE id = ?");
    $user_check->bind_param('i', $user_id);
    $user_check->execute();
    $user_result = $user_check->get_result();
    
    if ($user_result->num_rows === 0) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'User tidak ditemukan'
        ]);
        exit;
    }
    $user_check->close();
    
    // Insert health check
    $query = "INSERT INTO health_checks (user_id, nama_tes, catatan, tanggal, waktu_pemeriksaan, status, created_at)
              VALUES (?, ?, ?, ?, ?, ?, NOW())";
    
    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    
    $stmt->bind_param('isssss', $user_id, $nama_tes, $catatan, $tanggal, $waktu_pemeriksaan, $status);
    
    if (!$stmt->execute()) {
        throw new Exception('Execute failed: ' . $stmt->error);
    }
    
    $health_check_id = $conn->insert_id;
    $stmt->close();
    
    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => 'Health check berhasil ditambahkan',
        'health_check_id' => $health_check_id,
        'user_id' => $user_id
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?>
