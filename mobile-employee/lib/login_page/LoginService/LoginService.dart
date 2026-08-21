import 'package:kliktoko/APIService/ApiService.dart';
import 'package:kliktoko/login_page/LoginModel/LoginModel.dart';

class LoginService {
  final ApiService _apiService = ApiService();

  Future<LoginResponse> login(String username, String password) async {
    try {
      print('LoginService: Attempting login for user: $username');
      final loginData = LoginModel(
        name: username,
        password: password,
      );

      final response = await _apiService.login(loginData);
      print('LoginService: Login response received, success: ${response.success}');
      return response;
    } catch (e) {
      print('LoginService error: $e');
      throw e;
    }
  }
}