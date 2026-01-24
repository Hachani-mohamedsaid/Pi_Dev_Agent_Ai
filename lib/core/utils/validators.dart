class Validators {
  const Validators._();

  static String? nonEmpty(String? value, {String message = 'Required'}) {
    if (value == null) return message;
    if (value.trim().isEmpty) return message;
    return null;
  }
}


