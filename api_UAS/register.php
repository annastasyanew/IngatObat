<?php
/**
 * API Endpoint untuk Register User
 * Fungsi: Membuat akun user baru dengan email dan password
 * Method: POST
 */
include 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

$name = $data['name'] ?? '';
$email = $data['email'] ?? '';
$password = $data['password'] ?? '';

// Validasi input
if (empty($name) || empty($email) || empty($password)) {
    echo json_encode([
        'success' => false,
        'message' => 'Semua field harus diisi'
    ]);
    exit;
}

// Validasi email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode([
        'success' => false,
        'message' => 'Format email tidak valid'
    ]);
    exit;
}

// Cek apakah email sudah terdaftar
$checkSql = "SELECT id FROM users WHERE email = ?";
$checkStmt = $conn->prepare($checkSql);
$checkStmt->bind_param('s', $email);
$checkStmt->execute();
$checkResult = $checkStmt->get_result();

if ($checkResult->num_rows > 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Email sudah terdaftar'
    ]);
    $checkStmt->close();
    exit;
}
$checkStmt->close();

// Hash password
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

// Insert user baru
$sql = "INSERT INTO users (name, email, password) VALUES (?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param('sss', $name, $email, $hashedPassword);

if ($stmt->execute()) {
    $userId = $conn->insert_id;
    echo json_encode([
        'success' => true,
        'message' => 'Registrasi berhasil',
        'user' => [
            'id' => $userId,
            'name' => $name,
            'email' => $email
        ]
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Registrasi gagal: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
