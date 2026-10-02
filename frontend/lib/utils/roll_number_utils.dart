/// Roll-number rules used by the current project.
///
/// Current format:
///   YY + two letters + 1A/5A + four digits
///
/// Year mapping in the existing application:
///   26 -> First Year
///   25 -> Second Year
///   24 -> Third Year
///   23 -> Fourth Year
///
/// A 5A lateral-entry code advances the derived year by one.
class RollNumberUtils {
  static String? yearFromRollNumber(String rollNo) {
    final normalized = rollNo.trim().toUpperCase();
    final match = RegExp(r'^\d{2}[A-Z]{2}[15]A\d{4}$').firstMatch(normalized);
    if (match == null) return null;

    final prefix = normalized.substring(0, 2);
    final lateral = normalized.substring(4, 6) == '5A';

    int? year;
    switch (prefix) {
      case '26':
        year = 1;
        break;
      case '25':
        year = 2;
        break;
      case '24':
        year = 3;
        break;
      case '23':
        year = 4;
        break;
      default:
        return null;
    }

    if (lateral) year++;
    if (year > 4) return null;
    return switch (year) {
      1 => 'First Year',
      2 => 'Second Year',
      3 => 'Third Year',
      4 => 'Fourth Year',
      _ => null,
    };
  }
}
