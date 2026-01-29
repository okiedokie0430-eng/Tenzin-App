class Validators {
  Validators._();

  static const int minPasswordLength = 8;
  static const int maxMessageLength = 1000;
  static const int maxDisplayNameLength = 50;
  static const int minDisplayNameLength = 2;

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'И-мэйл хаяг оруулна уу';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Зөв и-мэйл хаяг оруулна уу';
    }
    
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Нууц үг оруулна уу';
    }
    
    if (value.length < minPasswordLength) {
      return 'Нууц үг хамгийн багадаа $minPasswordLength тэмдэгт байх ёстой';
    }
    
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Нууц үгээ баталгаажуулна уу';
    }
    
    if (value != password) {
      return 'Нууц үг таарахгүй байна';
    }
    
    return null;
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Нэр оруулна уу';
    }
    
    if (value.length < minDisplayNameLength) {
      return 'Нэр хамгийн багадаа $minDisplayNameLength тэмдэгт байх ёстой';
    }
    
    if (value.length > maxDisplayNameLength) {
      return 'Нэр хамгийн ихдээ $maxDisplayNameLength тэмдэгт байх ёстой';
    }
    
    return null;
  }

  static String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Зурвас оруулна уу';
    }
    
    if (value.length > maxMessageLength) {
      return 'Зурвас хамгийн ихдээ $maxMessageLength тэмдэгт байх ёстой';
    }
    
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName оруулна уу';
    }
    return null;
  }

  static bool isValidUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }
}
