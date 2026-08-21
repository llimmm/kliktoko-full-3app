class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String code;
  final int isActive;
  final int isCheckedIn;
  final String? lastCheckIn;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.code,
    required this.isActive,
    required this.isCheckedIn,
    this.lastCheckIn,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      code: json['code'] ?? '',
      isActive: json['is_active'] is int
          ? json['is_active']
          : int.tryParse(json['is_active'].toString()) ?? 0,
      isCheckedIn: json['is_checked_in'] is int
          ? json['is_checked_in']
          : int.tryParse(json['is_checked_in'].toString()) ?? 0,
      lastCheckIn: json['last_check_in'],
    );
  }
}
