<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    // Get user_id dari request parameter
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;
    
    // Validasi user_id
    if (!$user_id) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'User ID tidak ditemukan. Parameter user_id diperlukan.',
            'data' => []
        ]);
        exit;
    }
    
    include 'config.php';
    
    // Query dengan filter user_id
    $sql = "SELECT id, user_id, nama_tes, catatan, tanggal, waktu_pemeriksaan, status, created_at, updated_at 
            FROM health_checks 
            WHERE user_id = ? 
            ORDER BY tanggal DESC, waktu_pemeriksaan DESC";
    
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }
    
    $stmt->bind_param('i', $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $health_checks = [];
    while ($row = $result->fetch_assoc()) {
        $health_checks[] = $row;
    }
    
    $stmt->close();
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Health checks retrieved successfully',
        'data' => $health_checks,
        'total' => count($health_checks),
        'user_id' => $user_id
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage(),
        'data' => []
    ]);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?>
