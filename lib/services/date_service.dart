import 'package:intl/intl.dart';

class DateService {
  // You can change this anchor date to match your actual start date
  static final DateTime anchorDate = DateTime(2026, 1, 5); 

  static DateTime getStartOfCurrentFortnight() {
    DateTime now = DateTime.now();
    int daysDifference = now.difference(anchorDate).inDays;
    
    // Modulo 14 finds how many days we are into the current cycle
    int daysIntoCycle = daysDifference % 14;
    
    // Subtract those days to get back to the start (Monday)
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: daysIntoCycle));
  }

  static String formatRange(DateTime start) {
    DateTime end = start.add(const Duration(days: 13));
    DateFormat formatter = DateFormat('MMM d'); // e.g., Jan 12
    return "${formatter.format(start)} — ${formatter.format(end)}";
  }
}