import 'dart:math';

class UuidGenerator {
  static String generate() {
    const chars = 'abcdef0123456789';
    final random = Random();
    final buffer = StringBuffer();

    for (int i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        buffer.write('-');
      } else {
        buffer.write(chars[random.nextInt(chars.length)]);
      }
    }

    return buffer.toString();
  }
}
