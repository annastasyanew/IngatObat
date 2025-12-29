<?php
/**
 * API Endpoint untuk Login User
 * Fungsi: Verifikasi email dan password user, return user data jika valid
 * Method: POST
 */
include 'config.php';

$data = json_decode(file_get_contents('php://input'), true);

$email = $data['email'] ?? '';
$password = $data['password'] ?? '';

// Validasi input
if (empty($email) || empty($password)) {
    echo json_encode([
        'success' => false,
        'message' => 'Email dan password harus diisi'
    ]);
    exit;
}

// Cari user berdasarkan email
$sql = "SELECT id, name, email, password FROM users WHERE email = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param('s', $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Email tidak terdaftar'
    ]);
    $stmt->close();
    exit;
}

$user = $result->fetch_assoc();

// Verifikasi password
if (password_verify($password, $user['password'])) {
    echo json_encode([
        'success' => true,
        'message' => 'Login berhasil',
        'user' => [
            'id' => $user['id'],
            'name' => $user['name'],
            'email' => $user['email']
        ]
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Password salah'
    ]);
}

$stmt->close();
$conn->close();
