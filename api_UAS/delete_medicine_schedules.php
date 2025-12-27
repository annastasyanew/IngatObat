<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

$user_id = $input['user_id'] ?? null;
$medicine_id = $input['medicine_id'] ?? null;

if (!$user_id || !$medicine_id) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields: user_id, medicine_id']);
    exit;
}

try {
    // Verify user owns this medicine
    $verify_query = "SELECT id FROM medicines WHERE id = ? AND user_id = ?";
    $verify_stmt = $conn->prepare($verify_query);
    
    if (!$verify_stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $verify_stmt->bind_param("ii", $medicine_id, $user_id);
    $verify_stmt->execute();
    $verify_result = $verify_stmt->get_result();
    
    if ($verify_result->num_rows === 0) {
        http_response_code(403);
        echo json_encode(['success' => false, 'error' => 'Unauthorized - medicine not found']);
        $verify_stmt->close();
        exit;
    }
    
    $verify_stmt->close();
    
    // Delete schedules for this medicine
    $delete_query = "DELETE FROM schedules WHERE medicine_id = ? AND user_id = ?";
    $delete_stmt = $conn->prepare($delete_query);
    
    if (!$delete_stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $delete_stmt->bind_param("ii", $medicine_id, $user_id);
    
    if (!$delete_stmt->execute()) {
        throw new Exception("Execute failed: " . $delete_stmt->error);
    }
    
    $affected_rows = $delete_stmt->affected_rows;
    $delete_stmt->close();
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => "Schedules deleted successfully",
        'deleted_count' => $affected_rows
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Server error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
