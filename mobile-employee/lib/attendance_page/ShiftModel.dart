class ShiftModel {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final int lateTolerance;
  final dynamic lateThreshold;
  final String? salaryPerShift;
  final String? checkInTime;
  final String? checkOutTime;

  ShiftModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.lateTolerance = 15,
    this.lateThreshold,
    this.salaryPerShift,
    this.checkInTime,
    this.checkOutTime,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    print('📊 Parsing shift from JSON: ${json.keys.join(', ')}');
    print('📋 Raw JSON data: $json');

    // Debug khusus untuk check_in_time dan check_out_time
    print('🔍 Debug check_in_time:');
    print('   - Key exists: ${json.containsKey('check_in_time')}');
    print('   - Value: ${json['check_in_time']}');
    print('   - Type: ${json['check_in_time']?.runtimeType}');

    print('🔍 Debug check_out_time:');
    print('   - Key exists: ${json.containsKey('check_out_time')}');
    print('   - Value: ${json['check_out_time']}');
    print('   - Type: ${json['check_out_time']?.runtimeType}');

    // Parse check_in_time dan check_out_time dengan aman
    String? checkInTime;
    String? checkOutTime;

    try {
      checkInTime = json['check_in_time']?.toString();
      checkOutTime = json['check_out_time']?.toString();

      print('✅ Parsed checkInTime: $checkInTime');
      print('✅ Parsed checkOutTime: $checkOutTime');
    } catch (e) {
      print('⚠️ Error parsing check_in_time/check_out_time: $e');
      checkInTime = null;
      checkOutTime = null;
    }

    // Parse start_time dan end_time dengan aman
    String startTime = '';
    String endTime = '';

    try {
      // Handle ISO datetime format (2025-08-16T00:30:00.000000Z)
      final startTimeRaw = json['start_time']?.toString() ?? '';
      final endTimeRaw = json['end_time']?.toString() ?? '';

      // Extract time part from ISO datetime if needed
      if (startTimeRaw.contains('T')) {
        final startDateTime = DateTime.tryParse(startTimeRaw);
        if (startDateTime != null) {
          startTime =
              '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}:00';
        } else {
          startTime = startTimeRaw;
        }
      } else {
        startTime = startTimeRaw;
      }

      if (endTimeRaw.contains('T')) {
        final endDateTime = DateTime.tryParse(endTimeRaw);
        if (endDateTime != null) {
          endTime =
              '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}:00';
        } else {
          endTime = endTimeRaw;
        }
      } else {
        endTime = endTimeRaw;
      }

      print('✅ Parsed startTime: $startTime');
      print('✅ Parsed endTime: $endTime');
    } catch (e) {
      print('⚠️ Error parsing start_time/end_time: $e');
      startTime = '';
      endTime = '';
    }

    return ShiftModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      startTime: startTime,
      endTime: endTime,
      lateTolerance: json['late_tolerance'] is int
          ? json['late_tolerance']
          : int.tryParse(json['late_tolerance'].toString()) ?? 15,
      lateThreshold: json['late_threshold'],
      salaryPerShift: json['salary_per_shift']?.toString(),
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
    );
  }

  // Method untuk mengecek apakah waktu saat ini berada dalam rentang shift
  bool isCurrentTimeInShift() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Validasi data check-in/out time
    if (checkInTime == null ||
        checkInTime!.isEmpty ||
        checkOutTime == null ||
        checkOutTime!.isEmpty) {
      print('⚠️ Shift $id: checkInTime atau checkOutTime tidak tersedia');
      print('   - checkInTime: $checkInTime');
      print('   - checkOutTime: $checkOutTime');
      return false;
    }

    // Parse waktu check-in dan check-out
    final startMinutes = _parseTimeToMinutes(checkInTime!);
    final endMinutes = _parseTimeToMinutes(checkOutTime!);

    if (startMinutes == 0 && endMinutes == 0) {
      print('⚠️ Shift $id: Format waktu tidak valid');
      print('   - checkInTime: $checkInTime');
      print('   - checkOutTime: $checkOutTime');
      return false;
    }

    print('🔍 Shift $id ($name):');
    print(
        '   - Waktu saat ini: ${now.hour}:${now.minute}:${now.second} ($currentMinutes menit)');
    print('   - Check-in time: $checkInTime ($startMinutes menit)');
    print('   - Check-out time: $checkOutTime ($endMinutes menit)');

    // Handle shift yang melewati tengah malam
    if (endMinutes < startMinutes) {
      // Shift melewati tengah malam (contoh: 22:00 - 06:00)
      final isInShift =
          currentMinutes >= startMinutes || currentMinutes < endMinutes;
      print(
          '🌙 Shift $id melewati tengah malam: ${isInShift ? "AKTIF" : "tidak aktif"}');
      print(
          '   - Kondisi: $currentMinutes >= $startMinutes || $currentMinutes < $endMinutes');
      return isInShift;
    }

    // Shift normal (contoh: 06:30 - 14:30)
    final isInShift =
        currentMinutes >= startMinutes && currentMinutes < endMinutes;
    print('🔄 Shift $id normal: ${isInShift ? "AKTIF" : "tidak aktif"}');
    print(
        '   - Kondisi: $currentMinutes >= $startMinutes && $currentMinutes < $endMinutes');
    return isInShift;
  }

  // Helper method untuk mengkonversi string waktu ke menit
  int _parseTimeToMinutes(String time) {
    try {
      print('🔍 Parsing time: "$time"');

      // Format HH:mm:ss atau HH:mm
      final parts = time.split(':');
      print('⏰ Split parts: $parts');

      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final totalMinutes = hours * 60 + minutes;
        print('⏰ Parsed time: $time -> $hours:$minutes -> $totalMinutes menit');
        return totalMinutes;
      }

      print('⚠️ Format waktu tidak valid: $time (parts: $parts)');
      return 0;
    } catch (e) {
      print('⚠️ Error parsing time to minutes: $e');
      return 0;
    }
  }

  // Method untuk format jam shift untuk display
  String getFormattedTimeRange() {
    if (checkInTime != null &&
        checkInTime!.isNotEmpty &&
        checkOutTime != null &&
        checkOutTime!.isNotEmpty) {
      return '$checkInTime - $checkOutTime';
    }
    return '$startTime - $endTime';
  }

  // Method untuk check apakah terlambat
  bool isLateForShift(DateTime checkInTime) {
    final checkInMinutes = checkInTime.hour * 60 + checkInTime.minute;

    if (this.checkInTime == null || this.checkInTime!.isEmpty) {
      print('⚠️ Shift $id: checkInTime tidak tersedia untuk late check');
      return false;
    }

    final startMinutes = _parseTimeToMinutes(this.checkInTime!);
    if (startMinutes == 0) {
      print('⚠️ Shift $id: Format waktu tidak valid untuk late check');
      return false;
    }

    // Tambahkan toleransi keterlambatan
    final lateMinutes = startMinutes + lateTolerance;
    print(
        '⏰ Shift $id late threshold: $lateMinutes menit (start: $startMinutes + tolerance: $lateTolerance)');

    return checkInMinutes > lateMinutes;
  }

  @override
  String toString() {
    return 'ShiftModel{id: $id, name: $name, timeRange: ${getFormattedTimeRange()}, lateTolerance: $lateTolerance}';
  }
}
