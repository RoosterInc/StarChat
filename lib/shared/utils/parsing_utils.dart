class ParsingUtils {
  static DateTime parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(value);
    } catch (_) {
      final match = RegExp(r'^(\d{8})_(\d{4,6})$').firstMatch(value);
      if (match != null) {
        final datePart = match.group(1)!;
        final timePart = match.group(2)!;
        final year = int.parse(datePart.substring(0, 4));
        final month = int.parse(datePart.substring(4, 6));
        final day = int.parse(datePart.substring(6, 8));
        final hour = int.parse(timePart.substring(0, 2));
        final minute = int.parse(timePart.substring(2, 4));
        final second =
            timePart.length > 4 ? int.parse(timePart.substring(4, 6)) : 0;
        return DateTime(year, month, day, hour, minute, second);
      }
      return DateTime.now();
    }
  }

  static int parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
