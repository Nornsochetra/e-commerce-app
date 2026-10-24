import 'package:intl/intl.dart';

/// 89 → "$89.00"
String formatMoney(double amount) => NumberFormat.currency(locale: 'en_US', symbol: r'$').format(amount);

/// "Oct 16, 2026"
String formatDate(DateTime date) => DateFormat('MMM d, y').format(date.toLocal());

/// "Oct 16, 9:27 PM"
String formatDateTime(DateTime date) => DateFormat('MMM d, h:mm a').format(date.toLocal());

/// "Just now", "5 min ago", "2 hours ago", "Yesterday", "3 days ago", then the date.
String timeAgo(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return formatDate(date);
}

/// "PREMIUM_PICK" → "Premium Pick", "cash_on_delivery" → "Cash On Delivery"
String formatLabel(String value) => value
    .toLowerCase()
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');
