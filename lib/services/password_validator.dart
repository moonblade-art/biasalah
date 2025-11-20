class PasswordValidator {
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    
    if (password.length < 8) {
      return 'Password minimal 8 karakter';
    }
    
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password)) {
      return 'Password harus mengandung huruf dan angka';
    }
    
    return null;
  }
  
  static int checkPasswordLevel(String password) {
    if (password.isEmpty) return 0;
    
    int level = 0;
    int criteriaMet = 0;
    
    // Kriteria 1: Panjang minimal 6
    if (password.length >= 6) {
      criteriaMet++;
    }
    
    // Kriteria 2: Panjang minimal 8 + huruf & angka
    if (password.length >= 8 && 
        RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password)) {
      criteriaMet++;
    }
    
    // Kriteria 3: Panjang minimal 10 + kompleks
    if (password.length >= 10 &&
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])').hasMatch(password)) {
      criteriaMet++;
    }
    
    return criteriaMet;
  }

  // Method untuk detail validation
  static Map<String, bool> getPasswordCriteria(String password) {
    return {
      'min_8_chars': password.length >= 8,
      'has_letter': RegExp(r'[a-zA-Z]').hasMatch(password),
      'has_number': RegExp(r'\d').hasMatch(password),
      'has_uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'has_lowercase': RegExp(r'[a-z]').hasMatch(password),
    };
  }
}