<?php
/**
 * API Endpoint untuk Tambah Jadwal Obat dengan Perulangan
 * Fungsi: Menyimpan jadwal obat dengan tipe repeat (harian, mingguan, custom)
 * Method: POST
 */
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
$waktu_minum = $input['waktu_minum'] ?? null;
$tanggal_mulai = $input['tanggal_mulai'] ?? null;
$repeat_type = $input['repeat_type'] ?? 'once';
$jumlah_hari = $input['jumlah_hari'] ?? null;
$repeat_days = $input['repeat_days'] ?? null;
$repeat_until = $input['repeat_until'] ?? null;

if (!$user_id || !$medicine_id || !$waktu_minum || !$tanggal_mulai) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields']);
    exit;
}

try {
    // Verify user owns this medicine & get nama_obat and dosis
    $verify_query = "SELECT nama_obat, dosis FROM medicines WHERE id = ? AND user_id = ?";
    $verify_stmt = $conn->prepare($verify_query);
    
    if (!$verify_stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $verify_stmt->bind_param("ii", $medicine_id, $user_id);
    $verify_stmt->execute();
    $verify_result = $verify_stmt->get_result();
    
    if ($verify_result->num_rows === 0) {
        http_response_code(403);
        echo json_encode(['success' => false, 'error' => 'Unauthorized']);
        $verify_stmt->close();
        exit;
    }
    
    $row = $verify_result->fetch_assoc();
    $nama_obat = $row['nama_obat'];
    $dosis = $row['dosis'];
    $verify_stmt->close();
    
    // Handle berbagai repeat type
    $jadwal_dibuat = 0;
    $tanggal_current = new DateTime($tanggal_mulai);
    $created_ids = [];
    
    if ($repeat_type === 'once') {
        // Single schedule on tanggal_mulai
        $status = 'N';
        $insert_query = "INSERT INTO schedules (user_id, medicine_id, nama_obat, dosis, tanggal, waktu_minum, status) 
                        VALUES (?, ?, ?, ?, ?, ?, ?)";
        $insert_stmt = $conn->prepare($insert_query);
        
        if (!$insert_stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $insert_stmt->bind_param("iisssss", $user_id, $medicine_id, $nama_obat, $dosis, $tanggal_mulai, $waktu_minum, $status);
        
        if (!$insert_stmt->execute()) {
            throw new Exception("Execute failed: " . $insert_stmt->error);
        }
        
        $created_ids[] = $insert_stmt->insert_id;
        $jadwal_dibuat = 1;
        $insert_stmt->close();
        
    } else if ($repeat_type === 'daily') {
        // Daily for jumlah_hari days
        $hari_count = $jumlah_hari ?? 7;
        $status = 'N';
        
        for ($i = 0; $i < $hari_count; $i++) {
            $tanggal_str = $tanggal_current->format('Y-m-d');
            
            $insert_query = "INSERT INTO schedules (user_id, medicine_id, nama_obat, dosis, tanggal, waktu_minum, status) 
                            VALUES (?, ?, ?, ?, ?, ?, ?)";
            $insert_stmt = $conn->prepare($insert_query);
            
            if (!$insert_stmt) {
                throw new Exception("Prepare failed: " . $conn->error);
            }
            
            $insert_stmt->bind_param("iisssss", $user_id, $medicine_id, $nama_obat, $dosis, $tanggal_str, $waktu_minum, $status);
            
            if (!$insert_stmt->execute()) {
                throw new Exception("Execute failed: " . $insert_stmt->error);
            }
            
            $created_ids[] = $insert_stmt->insert_id;
            $insert_stmt->close();
            
            $tanggal_current->modify('+1 day');
        }
        
        $jadwal_dibuat = $hari_count;
        
    } else if ($repeat_type === 'weekly') {
        // Weekly on specific days
        $hari_count = $jumlah_hari ?? 30;
        $selected_days = !empty($repeat_days) ? explode(',', $repeat_days) : [];
        $selected_days = array_map('intval', $selected_days);
        $status = 'N';
        
        $weeks_to_create = ceil($hari_count / 7);
        
        for ($week = 0; $week < $weeks_to_create; $week++) {
            foreach ($selected_days as $day_index) {
                // $day_index: 0=Monday, 1=Tuesday, ..., 6=Sunday
                $current_dow = (int)$tanggal_current->format('N') - 1;
                $days_ahead = ($day_index - $current_dow + 7) % 7;
                
                if ($week === 0 && $days_ahead === 0) {
                    $tanggal_str = $tanggal_current->format('Y-m-d');
                } else if ($week === 0) {
                    $temp_date = clone $tanggal_current;
                    $temp_date->modify("+{$days_ahead} days");
                    $tanggal_str = $temp_date->format('Y-m-d');
                } else {
                    $temp_date = clone $tanggal_current;
                    $days_total = $week * 7 + $days_ahead;
                    $temp_date->modify("+{$days_total} days");
                    $tanggal_str = $temp_date->format('Y-m-d');
                }
                
                $insert_query = "INSERT INTO schedules (user_id, medicine_id, nama_obat, dosis, tanggal, waktu_minum, status) 
                                VALUES (?, ?, ?, ?, ?, ?, ?)";
                $insert_stmt = $conn->prepare($insert_query);
                
                if (!$insert_stmt) {
                    throw new Exception("Prepare failed: " . $conn->error);
                }
                
                $insert_stmt->bind_param("iisssss", $user_id, $medicine_id, $nama_obat, $dosis, $tanggal_str, $waktu_minum, $status);
                
                if (!$insert_stmt->execute()) {
                    // Silently ignore duplicates
                    if (strpos($insert_stmt->error, 'Duplicate') === false) {
                        throw new Exception("Execute failed: " . $insert_stmt->error);
                    }
                } else {
                    $created_ids[] = $insert_stmt->insert_id;
                    $jadwal_dibuat++;
                }
                
                $insert_stmt->close();
            }
        }
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => "Schedules created successfully",
        'jadwal_dibuat' => $jadwal_dibuat,
        'created_ids' => $created_ids
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
