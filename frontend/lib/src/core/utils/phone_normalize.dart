/// Канонический номер для API: `+7` и 10 цифр после (как на бэкенде).
String? normalizeRuPhoneForApi(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('8')) {
    digits = '7${digits.substring(1)}';
  } else if (digits.length == 10 && digits.startsWith('9')) {
    digits = '7$digits';
  }
  if (digits.length == 11 && digits.startsWith('7')) {
    return '+$digits';
  }
  return null;
}
