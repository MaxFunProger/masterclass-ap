import '../strings.dart';

class DateFormatter {
  static String format(String isoDate) {
    if (isoDate.isEmpty) return AppStrings.soonDate;
    try {
      // Handle "YYYY-MM-DD"
      final parts = isoDate.split('-');
      if (parts.length != 3) return isoDate;

      final day = int.parse(parts[2]);
      final month = int.parse(parts[1]);

      return "$day ${AppStrings.monthsGenitive[month]}";
    } catch (e) {
      return isoDate;
    }
  }
}
