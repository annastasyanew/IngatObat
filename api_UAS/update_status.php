<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

$schedule_id = $data['id'] ?? null;
$user_id = $data['user_id'] ?? null;
$status = $data['status'] ?? 'N';

// Normalize status - accept Y, N, sudah, selesai, yes, true, etc.
$status = strtoupper(trim($status));
if (in_array($status, ['SUDAH', 'SELESAI', 'YES', 'TRUE', '1', 'Y'])) {
    $status = 'Y';
} else {
    $status = 'N';
}

// Validate required fields
if (empty($schedule_id) || empty($user_id)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing id or user_id']);
    exit;
}

try {
    // Check ownership
    $check_sql = "SELECT id FROM schedules WHERE id = ? AND user_id = ?";
    $check_stmt = $conn->prepare($check_sql);
    
    if (!$check_stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $check_stmt->bind_param('ii', $schedule_id, $user_id);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();
    
    if ($check_result->num_rows === 0) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Schedule not found']);
        $check_stmt->close();
        exit;
    }
    
    $check_stmt->close();
    
    // Update status
    $sql = "UPDATE schedules SET status = ?, updated_at = NOW() WHERE id = ? AND user_id = ?";
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $stmt->bind_param('sii', $status, $schedule_id, $user_id);
    
    if (!$stmt->execute()) {
        throw new Exception("Execute failed: " . $stmt->error);
    }
    
    if ($stmt->affected_rows > 0) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Status updated to ' . $status
        ]);
    } else {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'No rows updated']);
    }
    
    $stmt->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

$conn->close();
?>
