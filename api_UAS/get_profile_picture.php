<?php
// get_profile_picture.php - Backend PHP untuk menampilkan profile picture

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    exit();
}

// Get user ID from query parameter
$userId = $_GET['id'] ?? $_GET['user_id'] ?? null;

if (!$userId || !is_numeric($userId)) {
    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Missing or invalid user ID']);
    exit();
}

// Database connection
require_once 'config.php';

try {
    // Query untuk get profile picture path dari database
    $query = "SELECT profile_picture FROM users WHERE id = ?";
    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        http_response_code(500);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Query preparation failed']);
        exit();
    }

    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        http_response_code(404);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'User not found']);
        exit();
    }

    $row = $result->fetch_assoc();
    $profilePicturePath = $row['profile_picture'];

    $stmt->close();
    $conn->close();

    // Check if file exists
    if (!$profilePicturePath || !file_exists($profilePicturePath)) {
        http_response_code(404);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Profile picture not found', 'path' => $profilePicturePath ?? 'NULL']);
        exit();
    }

    // Get file MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $profilePicturePath);
    finfo_close($finfo);

    if (!$mimeType) {
        $mimeType = 'image/png'; // Default fallback
    }

    // Set headers untuk serve image
    header('Content-Type: ' . $mimeType);
    header('Content-Length: ' . filesize($profilePicturePath));
    header('Cache-Control: public, max-age=3600'); // Cache for 1 hour
    
    // Output file
    readfile($profilePicturePath);
    exit();

} catch (Exception $e) {
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Server error: ' . $e->getMessage()]);
    exit();
}
?>
    
    $row = $result->fetch_assoc();
    $profile_picture = $row['profile_picture'];
    $stmt->close();
    
    if (!$profile_picture || !file_exists($profile_picture)) {
        http_response_code(404);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Profile picture not found']);
        exit();
    }
    
    // Serve the image file
    $mime_type = mime_content_type($profile_picture);
    header('Content-Type: ' . $mime_type);
    header('Content-Length: ' . filesize($profile_picture));
    readfile($profile_picture);
    
} catch (Exception $e) {
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

$conn->close();
?>
