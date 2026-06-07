class NumberValidator {
  static bool isInteger(String? string) {
    if (string == null) {
      return false;
    }

    try {
      int.parse(string);
    } on Exception catch (_) {
      return false;
    }

    return true;
  }

  static bool isNumeric(String? string) {
    if (string == null) {
      return false;
    }

    try {
      double.parse(string);
    } on Exception catch (_) {
      return false;
    }

    return true;
  }
}
