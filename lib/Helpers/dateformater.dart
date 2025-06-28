// Date formatter utility function
String formattedDate() {
  final now = DateTime.now();
  final months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  return '${months[now.month - 1]} ${now.day}, ${now.year}';
}