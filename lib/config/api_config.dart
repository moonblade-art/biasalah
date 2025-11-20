class ApiConfig {
  static const String baseUrl = "http://192.168.56.1/flutter_auth";
  
  static const String register = "$baseUrl/register.php";
  static const String sendVerification = "$baseUrl/send_verification.php";
  static const String verifyCode = "$baseUrl/verify_code.php";
  static const String login = "$baseUrl/login.php"; // TAMBAH INI
}