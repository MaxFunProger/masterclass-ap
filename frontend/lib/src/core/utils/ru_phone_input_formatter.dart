import 'package:flutter/services.dart';

class RuPhoneInputFormatter extends TextInputFormatter {
  static const String _prefix = '+7';
  static const int _maxDigits = 10;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    var rest = digits;

    if (rest.startsWith('7')) {
      rest = rest.substring(1);
    }

    if (rest.length > _maxDigits) {
      rest = rest.substring(0, _maxDigits);
    }

    final text = _format(rest);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  static String _format(String rest) {
    final buffer = StringBuffer(_prefix);
    if (rest.isEmpty) return buffer.toString();

    buffer.write(' ');
    buffer.write(rest.substring(0, rest.length.clamp(0, 3)));
    if (rest.length <= 3) return buffer.toString();

    buffer.write(' ');
    buffer.write(rest.substring(3, rest.length.clamp(3, 6)));
    if (rest.length <= 6) return buffer.toString();

    buffer.write('-');
    buffer.write(rest.substring(6, rest.length.clamp(6, 8)));
    if (rest.length <= 8) return buffer.toString();

    buffer.write('-');
    buffer.write(rest.substring(8, rest.length.clamp(8, 10)));
    return buffer.toString();
  }

  static bool isValid(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 && digits.startsWith('7');
  }
}
