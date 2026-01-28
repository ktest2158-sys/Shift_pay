import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/date_service.dart';

class GrossBreakdownScreen extends StatefulWidget {
  final DateTime fortnightStart;
  const GrossBreakdownScreen({super.key, required this.fortnightStart});

  @override
  State<GrossBreakdownScreen> createState() => _GrossBreakdownScreenState();
}

class _GrossBreakdownScreenState extends State<GrossBreakdownScreen> {
  final StorageService _storage = StorageService();

  // Helper to show the Edit Dialog
  void _showEditLoadingDialog(double currentCalc) {
    String key = "loading_${widget.fortnightStart.year}-${widget.fortnightStart.month}-${widget.fortnightStart.day}";
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manual Loading Override"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "Enter amount (e.g. 234.54)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              double? val = double.tryParse(controller.text);
              if (val != null) {
                _storage.saveManualLoading(key, val);
                setState(() {});
                Navigator.pop(context);
              }
            }, 
            child: const Text("Save & Lock")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _storage.getSettings();
    String loadingKey = "loading_${widget.fortnightStart.year}-${widget.fortnightStart.month}-${widget.fortnightStart.day}";
    
    double workedHrs = 0;
    double pmHrs = 0;
    double satHrs = 0;
    double sunHrs = 0;
    double alHrs = 0;
    double slHrs = 0;

    double pmLoadingAmt = 0;
    double satLoadingAmt = 0;
    double sunLoadingAmt = 0;
    
    // Check if we have a locked manual amount
    double? manualLoading = _storage.getManualLoading(loadingKey);
    double calculatedLeaveLoading = 0;

    for (int i = 0; i < 14; i++) {
      DateTime date = widget.fortnightStart.add(Duration(days: i));
      String key = "${date.year}-${date.month}-${date.day}";
      final shift = _storage.getShift(key);
      
      double hours = shift['hours'] ?? 0.0;
      String type = shift['type'] ?? 'Ordinary';

      if (hours > 0) {
        if (type == 'AL') {
          alHrs += hours;
          // Calculate 17.5% only if not manually overridden
          calculatedLeaveLoading += hours * (settings.baseRate * 0.175);
        } else if (type == 'SL') {
          slHrs += hours;
        } else {
          workedHrs += hours;
          if (date.weekday == DateTime.saturday) {
            satHrs += hours;
            satLoadingAmt += hours * (settings.baseRate * settings.satLoading);
          } else if (date.weekday == DateTime.sunday) {
            sunHrs += hours;
            sunLoadingAmt += hours * (settings.baseRate * settings.sunLoading);
          } else if (type == 'PM') {
            pmHrs += hours;
            pmLoadingAmt += hours * (settings.baseRate * settings.pmLoading);
          }
        }
      }
    }

    // Use manual if it exists, otherwise use calculated
    double finalLeaveLoading = manualLoading ?? calculatedLeaveLoading;
    
    double workedBasePay = workedHrs * settings.baseRate;
    double alBasePay = alHrs * settings.baseRate;
    double slBasePay = slHrs * settings.baseRate;
    double grandTotal = workedBasePay + alBasePay + slBasePay + pmLoadingAmt + satLoadingAmt + sunLoadingAmt + finalLeaveLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Pay Breakdown')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(DateService.formatRange(widget.fortnightStart), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            _breakdownRow("Ordinary Base Pay", workedHrs, workedBasePay),
            if (pmHrs > 0) _breakdownRow("PM Loading (Weekdays)", pmHrs, pmLoadingAmt),
            if (satHrs > 0) _breakdownRow("Saturday Loading", satHrs, satLoadingAmt),
            if (sunHrs > 0) _breakdownRow("Sunday Loading", sunHrs, sunLoadingAmt),
            if (alHrs > 0) _breakdownRow("Annual Leave Base", alHrs, alBasePay),
            if (slHrs > 0) _breakdownRow("Sick Leave Pay", slHrs, slBasePay),
            
            // Leave Loading Row with Lock/Edit Button
            if (alHrs > 0) Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: Text("Leave Loading (Locked if edited)", style: TextStyle(fontSize: 15))),
                  Expanded(flex: 1, child: Text("${alHrs.toStringAsFixed(1)} hrs", style: TextStyle(color: Colors.grey[600]))),
                  Text("\$${finalLeaveLoading.toStringAsFixed(2)}", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: manualLoading != null ? Colors.blue : Colors.black)),
                  IconButton(
                    icon: Icon(manualLoading != null ? Icons.lock : Icons.edit, size: 18, color: Colors.blue),
                    onPressed: () => _showEditLoadingDialog(calculatedLeaveLoading),
                  )
                ],
              ),
            ),
            
            const Spacer(),
            _totalRow("Total Gross", grandTotal, (workedHrs + alHrs + slHrs)),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, double hours, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 15))),
          Expanded(flex: 1, child: Text("${hours.toStringAsFixed(1)} hrs", style: TextStyle(color: Colors.grey[600]))),
          Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 48), // Match width of IconButton
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, double totalHrs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Total Hours: ${totalHrs.toStringAsFixed(1)}", style: const TextStyle(fontSize: 14)),
            ],
          ),
          Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}