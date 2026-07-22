/// Utility helpers used across the app.
class FormatUtils {
  /// Formats a large number with K/M suffix.
  /// e.g. 1500 → "1.5K", 2000000 → "2.0M"
  static String formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  /// Truncates a string to [max] characters and appends "…".
  static String truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}…' : s;

  /// Formats a DateTime as "DD/MM HH:mm".
  static String formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
