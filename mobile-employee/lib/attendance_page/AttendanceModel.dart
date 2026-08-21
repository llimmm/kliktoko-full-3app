class AttendanceModel {
  final bool isCheckedIn;
  final String date;
  final String shiftId;
  final String? checkInTime;
  final String? checkOutTime;
  final String? username;
  final String? userId;
  final bool isLate;

  AttendanceModel({
    required this.isCheckedIn,
    required this.date,
    required this.shiftId,
    this.checkInTime,
    this.checkOutTime,
    this.username,
    this.userId,
    this.isLate = false,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    // PERBAIKAN: Tambahkan logging untuk help debugging
    print('📊 Processing attendance model from JSON: ${json.keys.join(', ')}');

    // Parse check-in time to determine if late
    bool isUserLate = false;
    String? checkInTimeStr = json['check_in_time'] ?? json['check_in'] ?? '';

    if (checkInTimeStr != null && checkInTimeStr.isNotEmpty) {
      try {
        // Status terlambat ditentukan server, bukan di sini.
        //
        // Dulu ada cabang cadangan yang menghitungnya sendiri dengan ambang
        // 07:30 untuk shift 1 dan 14:30 untuk shift 2. Kedua angka itu tidak
        // pernah cocok dengan database, yang menyimpan 08:00 dan 15:00, dan
        // backend juga punya dua mekanisme keterlambatan sendiri
        // (late_tolerance dan late_threshold). Menandai karyawan terlambat
        // memakai ambang yang keliru jauh lebih merugikan daripada tidak
        // menandainya sama sekali, jadi tebakan itu dihapus.
        //
        // /api/attendance/history selalu menyertakan is_late.
        if (json.containsKey('is_late')) {
          isUserLate = json['is_late'] == true;
        } else {
          print('⚠️ is_late tidak dikirim API; status terlambat tidak ditebak');
        }
      } catch (e) {
        print('❌ Error determining late status: $e');
      }
    }

    // PERBAIKAN: Handle nested shift object more robustly
    String shiftId = '1';
    try {
      if (json.containsKey('shift')) {
        var shift = json['shift'];
        if (shift is Map<String, dynamic>) {
          shiftId = shift['id']?.toString() ?? '1';
        } else if (shift is String) {
          shiftId = shift;
        } else if (shift is int) {
          shiftId = shift.toString();
        }
      } else if (json.containsKey('shift_id')) {
        var shiftIdValue = json['shift_id'];
        if (shiftIdValue is String) {
          shiftId = shiftIdValue;
        } else if (shiftIdValue is int) {
          shiftId = shiftIdValue.toString();
        }
      }
    } catch (e) {
      print('❌ Error extracting shift ID: $e');
      shiftId = '1'; // Default to shift 1
    }

    print('📋 Final shift ID: $shiftId');

    // Handle different date formats
    String date = '';
    if (json.containsKey('date')) {
      String rawDate = json['date'].toString();
      // Convert ISO format to just date
      if (rawDate.contains('T')) {
        date = rawDate.split('T')[0];
      } else {
        date = rawDate;
      }
    } else {
      date = json['attendance_date'] ??
          json['created_at']?.toString().split('T')[0] ??
          '';
    }

    print('📋 Date extracted: $date');

    // Format check-in time for display
    String? formattedCheckInTime;
    if (checkInTimeStr != null && checkInTimeStr.isNotEmpty) {
      if (checkInTimeStr.contains('T')) {
        formattedCheckInTime = checkInTimeStr.split('T')[1].split('.')[0];
      } else if (checkInTimeStr.contains(' ')) {
        formattedCheckInTime = checkInTimeStr.split(' ')[1];
      } else {
        formattedCheckInTime = checkInTimeStr;
      }
    }

    print('📋 Formatted check-in time: $formattedCheckInTime');

    // Format check-out time for display
    String? checkOutTimeStr = json['check_out_time'] ?? json['check_out'] ?? '';
    String? formattedCheckOutTime;
    if (checkOutTimeStr != null && checkOutTimeStr.isNotEmpty) {
      if (checkOutTimeStr.contains('T')) {
        formattedCheckOutTime = checkOutTimeStr.split('T')[1].split('.')[0];
      } else if (checkOutTimeStr.contains(' ')) {
        formattedCheckOutTime = checkOutTimeStr.split(' ')[1];
      } else {
        formattedCheckOutTime = checkOutTimeStr;
      }
    }

    print('📋 Formatted check-out time: $formattedCheckOutTime');

    // PERBAIKAN: Lebih robust dalam menentukan apakah checked in
    bool isCheckedIn = false;
    if (json['checked_in'] == true || json['is_checked_in'] == true) {
      isCheckedIn = true;
    } else if (checkInTimeStr != null && checkInTimeStr.isNotEmpty) {
      isCheckedIn = true;
    } else if (json.containsKey('status') && json['status'] is String) {
      isCheckedIn =
          json['status'].toString().toLowerCase().contains('checked in');
    }

    print('📋 Is checked in: $isCheckedIn');

    return AttendanceModel(
      isCheckedIn: isCheckedIn,
      date: date,
      shiftId: shiftId,
      checkInTime: formattedCheckInTime,
      checkOutTime: formattedCheckOutTime,
      username: json['username'] ??
          json['user_name'] ??
          (json.containsKey('user') && json['user'] is Map
              ? json['user']['name']
              : ''),
      userId: json['user_id'] ??
          json['id']?.toString() ??
          (json.containsKey('user') && json['user'] is Map
              ? json['user']['id'].toString()
              : ''),
      isLate: isUserLate,
    );
  }

  // Empty model for when there's no attendance data
  factory AttendanceModel.empty() {
    return AttendanceModel(
      isCheckedIn: false,
      date: '',
      shiftId: '1',
    );
  }

  // Check if the user has checked out
  bool get hasCheckedOut => checkOutTime != null && checkOutTime!.isNotEmpty;

  @override
  String toString() {
    return 'AttendanceModel{isCheckedIn: $isCheckedIn, date: $date, shiftId: $shiftId, checkInTime: $checkInTime, checkOutTime: $checkOutTime, username: $username, isLate: $isLate}';
  }
}

// Model untuk data riwayat kehadiran dari API
class AttendanceHistoryModel {
  final String bulan;
  final int totalHariKerja;
  final int totalTerlambat;
  final List<AttendanceHistoryItem> history;

  AttendanceHistoryModel({
    required this.bulan,
    required this.totalHariKerja,
    required this.totalTerlambat,
    required this.history,
  });

  factory AttendanceHistoryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryModel(
      bulan: json['bulan'] ?? '',
      totalHariKerja: json['total_hari_kerja'] ?? 0,
      totalTerlambat: json['total_terlambat'] ?? 0,
      history: (json['history'] as List<dynamic>?)
              ?.map((item) => AttendanceHistoryItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class AttendanceHistoryItem {
  final String tanggal;
  final String namaShift;
  final String waktuShift;
  final String status;
  final String checkIn;
  final String checkOut;
  final String durasi;

  AttendanceHistoryItem({
    required this.tanggal,
    required this.namaShift,
    required this.waktuShift,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.durasi,
  });

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryItem(
      tanggal: json['tanggal'] ?? '',
      namaShift: json['nama_shift'] ?? '',
      waktuShift: json['waktu_shift'] ?? '',
      status: json['status'] ?? '',
      checkIn: json['check_in'] ?? '',
      checkOut: json['check_out'] ?? '',
      durasi: json['durasi'] ?? '',
    );
  }
}
