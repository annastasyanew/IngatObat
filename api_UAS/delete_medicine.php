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

$medicine_id = $data['id'] ?? null;
$user_id = $data['user_id'] ?? null;

// Validasi input
if (empty($medicine_id) || empty($user_id)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Medicine ID dan User ID tidak boleh kosong'
    ]);
    exit;
}

try {
    // Validasi bahwa medicine milik user sebelum delete
    $check_sql = "SELECT id FROM medicines WHERE id = ? AND user_id = ?";
    $check_stmt = $conn->prepare($check_sql);
    
    if (!$check_stmt) {
        throw new Exception('Prepare failed: ' . $conn->error);
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
    $check_stmt->close();
    
    // Start transaction untuk keamanan
    $conn->begin_transaction();
    
    // STEP 1: Delete schedules yang reference medicine ini
    $delete_schedules_sql = "DELETE FROM schedules WHERE medicine_id = ? AND user_id = ?";
    $delete_schedules_stmt = $conn->prepare($delete_schedules_sql);
    
    if (!$delete_schedules_stmt) {
        throw new Exception('Prepare delete schedules failed: ' . $conn->error);
    }
    
    $delete_schedules_stmt->bind_param('ii', $medicine_id, $user_id);
    
    if (!$delete_schedules_stmt->execute()) {
        throw new Exception('Delete schedules failed: ' . $delete_schedules_stmt->error);
    }
    
    $schedules_deleted = $delete_schedules_stmt->affected_rows;
    $delete_schedules_stmt->close();
    
    // STEP 2: Delete medicine
    $delete_medicine_sql = "DELETE FROM medicines WHERE id = ? AND user_id = ?";
    $delete_medicine_stmt = $conn->prepare($delete_medicine_sql);
    
    if (!$delete_medicine_stmt) {
        throw new Exception('Prepare delete medicine failed: ' . $conn->error);
    }
    
    $delete_medicine_stmt->bind_param('ii', $medicine_id, $user_id);
    
    if (!$delete_medicine_stmt->execute()) {
        throw new Exception('Delete medicine failed: ' . $delete_medicine_stmt->error);
    }
    
    $medicines_deleted = $delete_medicine_stmt->affected_rows;
    $delete_medicine_stmt->close();
    
    if ($medicines_deleted > 0) {
        // Commit transaction jika semua sukses
        $conn->commit();
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Obat berhasil dihapus',
            'schedules_deleted' => $schedules_deleted,
            'medicines_deleted' => $medicines_deleted
        ]);
    } else {
        // Rollback jika tidak ada medicine yang dihapus
        $conn->rollback();
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'Obat tidak ditemukan'
        ]);
    }
    
    $conn->close();
    
} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
    $conn->close();
}
?>
