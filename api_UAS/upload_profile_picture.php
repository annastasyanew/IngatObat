<?php
/**
 * API Endpoint untuk Upload Foto Profil
 * Fungsi: Menerima dan menyimpan foto profil user
 * Method: POST
 */
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit();
}

require_once 'config.php';

try {
    // Get user_id - try multiple sources for multipart/form-data compatibility
    $user_id = null;
    
    // Check all possible sources - accept both 'user_id' and 'id' field names
    if (isset($_POST['user_id']) && !empty($_POST['user_id'])) {
        $user_id = $_POST['user_id'];
    } elseif (isset($_POST['id']) && !empty($_POST['id'])) {
        $user_id = $_POST['id'];
    } elseif (isset($_REQUEST['user_id']) && !empty($_REQUEST['user_id'])) {
        $user_id = $_REQUEST['user_id'];
    } elseif (isset($_REQUEST['id']) && !empty($_REQUEST['id'])) {
        $user_id = $_REQUEST['id'];
    } elseif (isset($_GET['user_id']) && !empty($_GET['user_id'])) {
        $user_id = $_GET['user_id'];
    } elseif (isset($_GET['id']) && !empty($_GET['id'])) {
        $user_id = $_GET['id'];
    }
    
    // If still not found, return detailed error
    if (!$user_id) {
        http_response_code(400);
        echo json_encode([
            'success' => false, 
            'message' => 'Missing user_id or id parameter',
            'debug' => [
                'post_keys' => array_keys($_POST),
                'request_keys' => array_keys($_REQUEST),
                'files_keys' => array_keys($_FILES)
            ]
        ]);
        exit();
    }

    $user_id = intval($user_id);

    if (!isset($_FILES['profile_picture'])) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No file uploaded']);
        exit();
    }

    $file = $_FILES['profile_picture'];
    $file_name = $file['name'];
    $file_tmp = $file['tmp_name'];
    $file_size = $file['size'];
    $file_type = $file['type'];
    $file_error = $file['error'];

    // Validate file
    if ($file_error !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'File upload error: ' . $file_error]);
        exit();
    }

    // Check file size (max 5MB)
    if ($file_size > 5 * 1024 * 1024) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'File too large (max 5MB)']);
        exit();
    }

    // Check file type
    $allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!in_array($file_type, $allowed_types)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid file type. Allowed: JPEG, PNG, GIF, WebP']);
        exit();
    }

    // Create upload directory if not exists
    $upload_dir = __DIR__ . '/uploads/profile_pictures/';
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0755, true);
    }
    
    // Generate unique filename
    $file_extension = pathinfo($file_name, PATHINFO_EXTENSION);
    $new_filename = 'user_' . $user_id . '_' . time() . '.' . $file_extension;
    $file_path = $upload_dir . $new_filename;
    
    // Move uploaded file
    if (!move_uploaded_file($file_tmp, $file_path)) {
        throw new Exception('Failed to save file');
    }
    
    // Delete old profile picture if exists
    $old_file_query = "SELECT profile_picture FROM users WHERE id = ?";
    $old_file_stmt = $conn->prepare($old_file_query);
    
    if ($old_file_stmt) {
        $old_file_stmt->bind_param('i', $user_id);
        $old_file_stmt->execute();
        $old_file_result = $old_file_stmt->get_result();
        
        if ($old_file_result->num_rows > 0) {
            $old_file_row = $old_file_result->fetch_assoc();
            $old_file = $old_file_row['profile_picture'];
            
            if ($old_file && file_exists($old_file)) {
                unlink($old_file);
            }
        }
        
        $old_file_stmt->close();
    }
    
    // Update database with new profile picture path
    $update_query = "UPDATE users SET profile_picture = ? WHERE id = ?";
    $update_stmt = $conn->prepare($update_query);
    
    if (!$update_stmt) {
        throw new Exception('Database error: ' . $conn->error);
    }
    
    $update_stmt->bind_param('si', $file_path, $user_id);
    
    if (!$update_stmt->execute()) {
        throw new Exception('Failed to update database: ' . $update_stmt->error);
    }
    
    // Log for debugging
    $affected_rows = $update_stmt->affected_rows;
    
    $update_stmt->close();
    
    // Success response
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Profile picture uploaded successfully',
        'file_path' => $file_path,
        'file_name' => $new_filename,
        'db_updated' => $affected_rows > 0,
        'affected_rows' => $affected_rows
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
