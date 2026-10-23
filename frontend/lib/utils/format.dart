import 'package:intl/intl.dart';

/// Formatting that matches the copy in the designs. [now] is injectable for tests.
abstract final class Fmt {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _daysBetween(DateTime from, DateTime to) => _day(to).difference(_day(from)).inDays;

  /// "just now", "5m ago", "2h ago", "yesterday", "Mon", "24 Sep".
  static String ago(DateTime t, {DateTime? now}) {
    now ??= DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    final days = _daysBetween(t, now);
    if (days == 0) return '${diff.inHours}h ago';
    if (days == 1) return 'yesterday';
    if (days < 7) return DateFormat('EEE').format(t);
    return DateFormat('d MMM').format(t);
  }

  /// Issue age: "Yesterday", "6 days ago", "Today".
  static String age(DateTime t, {DateTime? now}) {
    now ??= DateTime.now();
    final days = _daysBetween(t, now);
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 30) return '$days days ago';
    return DateFormat('d MMM').format(t);
  }

  /// "6 days", "3 hours" - how long an issue has been waiting.
  static String waited(DateTime from, {DateTime? now}) {
    now ??= DateTime.now();
    final diff = now.difference(from);
    if (diff.inDays >= 1) return diff.inDays == 1 ? '1 day' : '${diff.inDays} days';
    if (diff.inHours >= 1) return diff.inHours == 1 ? '1 hour' : '${diff.inHours} hours';
    return 'under an hour';
  }

  /// Timeline stamp: "Today, 07:48", "Yesterday, 18:02", "Thu 24 Sep, 21:40".
  static String stamp(DateTime t, {DateTime? now}) {
    now ??= DateTime.now();
    final days = _daysBetween(t, now);
    final time = DateFormat('HH:mm').format(t);
    if (days == 0) return 'Today, $time';
    if (days == 1) return 'Yesterday, $time';
    return '${DateFormat('EEE d MMM').format(t)}, $time';
  }

  /// "Fri 25 Sep"
  static String day(DateTime t) => DateFormat('EEE d MMM').format(t);

  /// "22 Sep"
  static String dayMonth(DateTime t) => DateFormat('d MMM').format(t);

  /// "Wednesday 30 September" - friendlier header date.
  static String longToday() => DateFormat('EEEE d MMMM').format(DateTime.now());

  /// "Wed 30 Sep" header date.
  static String today() => DateFormat('EEE d MMM').format(DateTime.now());

  /// Range for grouped nudges: "Sat 26 – Sun 27 Sep".
  static String range(DateTime a, DateTime b) {
    if (_day(a) == _day(b)) return day(a);
    final sameMonth = a.month == b.month && a.year == b.year;
    final start = sameMonth ? DateFormat('EEE d').format(a) : day(a);
    return '$start – ${day(b)}';
  }

  /// Nudge cooldown: "21h 48m", "12m".
  static String countdown(Duration d) {
    final minutes = (d.inSeconds / 60).ceil();
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  static String ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    return switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' };
  }

  static String plural(int n, String one, [String? many]) => n == 1 ? '1 $one' : '$n ${many ?? '${one}s'}';

  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
