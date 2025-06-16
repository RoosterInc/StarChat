String formatRelativeTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays > 7) {
    return '${date.day}/${date.month}/${date.year}';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} days ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hours ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} minutes ago';
  } else {
    return 'Just now';
  }
}
