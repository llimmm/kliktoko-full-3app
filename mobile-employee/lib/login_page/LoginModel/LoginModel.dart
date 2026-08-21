class LoginModel {
  final String name;
  final String password;

  LoginModel({
    required this.name,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'password': password,
      };
}

class LoginResponse {
  final String token;
  final String message;
  final bool success;
  final Map<String, dynamic> user;

  LoginResponse({
    required this.token,
    required this.message,
    required this.success,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // More robust parsing of API response
    Map<String, dynamic> userData = {};
    String token = '';

    // Extract user data
    if (json.containsKey('data')) {
      var data = json['data'];
      if (data is Map) {
        // Try to get token from data
        token = data['token']?.toString() ?? '';

        // Try to get user from data.user
        if (data.containsKey('user') && data['user'] is Map) {
          userData = Map<String, dynamic>.from(data['user']);
        } else {
          // If no nested user object, data itself might be the user data
          userData = Map<String, dynamic>.from(data);
          // Remove token from user data if it exists there
          userData.remove('token');
        }
      }
    }

    // If token wasn't found in data, try at top level
    if (token.isEmpty && json.containsKey('token')) {
      token = json['token']?.toString() ?? '';
    }

    // If user data is still empty, check top level
    if (userData.isEmpty && json.containsKey('user') && json['user'] is Map) {
      userData = Map<String, dynamic>.from(json['user']);
    }

    // Determine success based on status or success field
    bool success = false;
    if (json.containsKey('status')) {
      var status = json['status'];
      success = status == true || status == 'success' || status == 1;
    } else if (json.containsKey('success')) {
      var successField = json['success'];
      success = successField == true ||
          successField == 'success' ||
          successField == 1;
    } else {
      // Fallback - consider successful if we have a token
      success = token.isNotEmpty;
    }

    String message = json['message']?.toString() ?? 'Login response received';

    print(
        'Parsed LoginResponse: token=${token.isNotEmpty ? 'Present' : 'Missing'}, '
        'userData=${userData.isNotEmpty ? userData : 'Empty'}, success=$success');

    return LoginResponse(
      token: token,
      message: message,
      success: success,
      user: userData,
    );
  }
}
