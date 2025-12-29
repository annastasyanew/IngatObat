<?php
/**
 * File Konfigurasi Database dan Header CORS
 * Fungsi: Menghubungkan aplikasi ke database MySQL dan setup CORS headers
 * Digunakan oleh: Semua API endpoint
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

$host = 'localhost';
$username = 'root';
$password = '';
$database = 'medicine_uas';

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    die(json_encode(['error' => 'Connection failed: ' . $conn->connect_error]));
}
