import 'package:flutter/material.dart';
import '../services/date_service.dart';
import '../services/storage_service.dart';
import 'shift_entry_screen.dart';
import 'settings_screen.dart';
import 'gross_breakdown_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime currentStart;
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _refreshDateRange();
  }

  void _refreshDateRange() {
    final settings = _storage.getSettings(); 
    final anchor = settings.anchorDate; 
    final today = DateTime.now();
    final difference = today.difference(anchor).inDays;
    final daysIntoCycle = difference % 14;
    
    setState(() {
      currentStart = DateTime(today.year, today.month, today.day).subtract(Duration(days: daysIntoCycle));
    });
  }

  void _moveFortnight(int days) {
    setState(() {
      currentStart = currentStart.add(Duration(days: days));
    });
  }

  /// Calculates PAYG Tax using official ATO Fortnightly math (Scale 1 & 2)
  double _calculateATOTax(double gross, bool claimThreshold) {
    // 1. Convert to weekly equivalent (ATO official method: divide by 2, ignore cents, add 99c)
    double weeklyEquivalent = (gross / 2).floorToDouble() + 0.99;
    
    double a = 0;
    double b = 0;

    if (claimThreshold) {
      // Scale 2: Resident claiming tax-free threshold
      if (weeklyEquivalent < 361) {
        a = 0.00; b = 0.00;
      } else if (weeklyEquivalent < 500) {
        a = 0.1600; b = 57.8462;
      } else if (weeklyEquivalent < 625) {
        a = 0.2600; b = 107.8462;
      } else if (weeklyEquivalent < 721) {
        a = 0.1800; b = 57.8462;
      } else if (weeklyEquivalent < 865) {
        a = 0.1890; b = 64.3365;
      } else if (weeklyEquivalent < 1282) {
        a = 0.3227; b = 180.0385;
      } else if (weeklyEquivalent < 2596) {
        a = 0.3200; b = 176.5769; 
      } else if (weeklyEquivalent < 3653) {
        a = 0.3900; b = 358.3077;
      } else {
        a = 0.4700; b = 650.6154;
      }
    } else {
      // Scale 1: Resident NOT claiming tax-free threshold
      if (weeklyEquivalent < 150) {
        a = 0.1600; b = 0.1600;
      } else if (weeklyEquivalent < 371) {
        a = 0.2117; b = 7.7550;
      } else if (weeklyEquivalent < 515) {
        a = 0.1890; b = -0.6702;
      } else if (weeklyEquivalent < 932) {
        a = 0.3227; b = 68.2367;
      } else if (weeklyEquivalent < 2246) {
        a = 0.3200; b = 65.7202;
      } else if (weeklyEquivalent < 3303) {
        a = 0.3900; b = 222.9510;
      } else {
        a = 0.4700; b = 487.2587;
      }
    }

    // 2. Calculate weekly tax and round to nearest dollar (ATO standard)
    double weeklyTax = (weeklyEquivalent * a) - b;
    
    // 3. Convert back to fortnightly
    return (weeklyTax.roundToDouble() * 2);
  }

  void _showEditTaxDialog() {
    String taxKey = "tax_${currentStart.year}-${currentStart.month}-${currentStart.day}";
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Exact Tax"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: "\$ ", hintText: "Tax from payslip"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              double? val = double.tryParse(controller.text);
              if (val != null) {
                _storage.saveManualTax(taxKey, val); //
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

  Map<String, double> _calculateTotals() {
    final settings = _storage.getSettings(); //
    double totalHours = 0;
    double totalGross = 0;

    String loadingKey = "loading_${currentStart.year}-${currentStart.month}-${currentStart.day}";
    String taxKey = "tax_${currentStart.year}-${currentStart.month}-${currentStart.day}";
    
    double? manualLoading = _storage.getManualLoading(loadingKey); //
    double? manualTax = _storage.getManualTax(taxKey); //
    double autoCalculatedLoading = 0;

    for (int i = 0; i < 14; i++) {
      DateTime date = currentStart.add(Duration(days: i));
      String key = "${date.year}-${date.month}-${date.day}";
      final shift = _storage.getShift(key); //
      
      double hours = shift['hours'] ?? 0.0;
      String type = shift['type'] ?? 'Ordinary'; 

      if (hours > 0) {
        totalHours += hours;
        double shiftPay = hours * settings.baseRate; 

        if (type == 'AL') {
          autoCalculatedLoading += hours * (settings.baseRate * settings.leaveLoading);
        } else if (type == 'SL') {
          // Sick leave is base rate
        } else {
          if (date.weekday == DateTime.saturday) {
            shiftPay += hours * (settings.baseRate * settings.satLoading);
          } else if (date.weekday == DateTime.sunday) {
            shiftPay += hours * (settings.baseRate * settings.sunLoading);
          } else if (type == 'PM') {
            shiftPay += hours * (settings.baseRate * settings.pmLoading);
          }
        }
        totalGross += shiftPay;
      }
    }

    totalGross += (manualLoading ?? autoCalculatedLoading);

    // Use professional ATO calculation with the threshold toggle
    double tax = manualTax ?? _calculateATOTax(totalGross, settings.taxFreeThreshold);
    if (tax < 0) tax = 0; 

    double net = totalGross - tax;

    return {'hours': totalHours, 'gross': totalGross, 'tax': tax, 'net': net};
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();
    String taxKey = "tax_${currentStart.year}-${currentStart.month}-${currentStart.day}";
    bool isTaxLocked = _storage.getManualTax(taxKey) != null; //

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _moveFortnight(-14)),
            Text(DateService.formatRange(currentStart)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _moveFortnight(14)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              _refreshDateRange();
            }
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _statCard('Shifts', totals['hours']!.toStringAsFixed(1), Icons.work, Colors.orange, onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => ShiftEntryScreen(fortnightStart: currentStart)));
                    setState(() {});
                  }),
                  _statCard('Gross Pay', '\$${totals['gross']!.toStringAsFixed(2)}', Icons.payments, Colors.green, onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => GrossBreakdownScreen(fortnightStart: currentStart)));
                    setState(() {}); 
                  }),
                  _statCard(
                    isTaxLocked ? 'Tax (Locked)' : 'Tax (ATO)', 
                    '\$${totals['tax']!.toStringAsFixed(2)}', 
                    Icons.account_balance, 
                    isTaxLocked ? Colors.blue : Colors.red,
                    onTap: _showEditTaxDialog
                  ),
                  _statCard('Next Pay', '\$${totals['net']!.toStringAsFixed(2)}', Icons.savings, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}