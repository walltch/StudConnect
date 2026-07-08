/// Small French relative-time formatter, replicating the web app's use of
/// date-fns `formatDistanceToNow`, without adding a package dependency for
/// a handful of buckets.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);

  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return 'il y a $m minute${m > 1 ? 's' : ''}';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return 'il y a $h heure${h > 1 ? 's' : ''}';
  }
  if (diff.inDays < 30) {
    final d = diff.inDays;
    return 'il y a $d jour${d > 1 ? 's' : ''}';
  }
  if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return 'il y a $months mois';
  }
  final years = (diff.inDays / 365).floor();
  return 'il y a $years an${years > 1 ? 's' : ''}';
}
