<?php
/**
 * API Endpoint untuk Edit/Update Health Check
 * Fungsi: Mengubah data pemeriksaan kesehatan yang sudah ada
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
    if (!isset($data['id']) || !isset($data['user_id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'ID dan user_id diperlukan'
        ]);
        exit;
    }
    
    $health_check_id = intval($data['id']);
    $user_id = intval($data['user_id']);
    
    include 'config.php';
    
    // CRITICAL: Verify ownership before update
    $ownership_check = $conn->prepare(
        "SELECT user_id FROM health_checks WHERE id = ?"
    );
    $ownership_check->bind_param('i', $health_check_id);
    $ownership_check->execute();
    $ownership_result = $ownership_check->get_result();
    
    if ($ownership_result->num_rows === 0) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Health check tidak ditemukan'
        ]);
        exit;
    }
    
    $row = $ownership_result->fetch_assoc();
    
    if ($row['user_id'] != $user_id) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Anda tidak memiliki izin untuk mengubah health check ini'
        ]);
        exit;
    }
    
    $ownership_check->close();
    
    // Get values
    $nama_tes = trim($data['nama_tes'] ?? '');
    $catatan = trim($data['catatan'] ?? '');
    $tanggal = trim($data['tanggal'] ?? '');
    $waktu_pemeriksaan = trim($data['waktu_pemeriksaan'] ?? '');
    $status = trim($data['status'] ?? '');
    
    // Normalize status: convert to Y or N only
    $status_lower = strtolower($status);
    if ($status_lower === 'y' || $status_lower === 'selesai' || $status_lower === 'sudah' || $status_lower === 'yes' || $status_lower === 'true' || $status === '1') {
        $status = 'Y';
    } else {
        $status = 'N';
    }
    
    // Update
    $query = "UPDATE health_checks 
              SET nama_tes = ?, catatan = ?, tanggal = ?, 
                  waktu_pemeriksaan = ?, status = ?, updated_at = NOW()
              WHERE id = ? AND user_id = ?";
    
    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    
    $stmt->bind_param('sssssii', $nama_tes, $catatan, $tanggal, 
                      $waktu_pemeriksaan, $status, $health_check_id, $user_id);
    
    if (!$stmt->execute()) {
        throw new Exception('Execute failed: ' . $stmt->error);
    }
    
    $stmt->close();
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Health check berhasil diperbarui',
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
