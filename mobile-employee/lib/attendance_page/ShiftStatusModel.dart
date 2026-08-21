import 'package:intl/intl.dart';

class ShiftStatusModel {
  final String message;
  final bool isActive;
  final ShiftStatusData? data;

  ShiftStatusModel({
    required this.message,
    required this.isActive,
    this.data,
  });

  factory ShiftStatusModel.fromJson(Map<String, dynamic> json) {
    return ShiftStatusModel(
      message: json['message'] ?? '',
      isActive: json['is_active'] ?? false,
      data:
          json['data'] != null ? ShiftStatusData.fromJson(json['data']) : null,
    );
  }

  factory ShiftStatusModel.empty() {
    return ShiftStatusModel(
      message: 'Belum absen',
      isActive: false,
      data: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'is_active': isActive,
      'data': data?.toJson(),
    };
  }
}

class ShiftStatusData {
  final int shiftNumber;
  final String shiftTime;
  final String duration;
  final bool isLate;
  final DateTime? checkIn;
  final DateTime? checkOut;

  ShiftStatusData({
    required this.shiftNumber,
    required this.shiftTime,
    required this.duration,
    required this.isLate,
    this.checkIn,
    this.checkOut,
  });

  factory ShiftStatusData.fromJson(Map<String, dynamic> json) {
    return ShiftStatusData(
      shiftNumber: json['shift_number'] ?? 0,
      shiftTime: json['shift_time'] ?? '',
      duration: json['duration'] ?? '',
      isLate: json['is_late'] ?? false,
      checkIn:
          json['check_in'] != null ? DateTime.parse(json['check_in']) : null,
      checkOut:
          json['check_out'] != null ? DateTime.parse(json['check_out']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shift_number': shiftNumber,
      'shift_time': shiftTime,
      'duration': duration,
      'is_late': isLate,
      'check_in': checkIn?.toIso8601String(),
      'check_out': checkOut?.toIso8601String(),
    };
  }

  String getFormattedCheckInTime() {
    if (checkIn == null) return '-';
    return DateFormat('HH:mm:ss').format(checkIn!);
  }

  String getFormattedCheckOutTime() {
    if (checkOut == null) return '-';
    return DateFormat('HH:mm:ss').format(checkOut!);
  }
}
