import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class ShiftEntryScreen extends StatefulWidget {
  final DateTime fortnightStart;
  const ShiftEntryScreen({super.key, required this.fortnightStart});

  @override
  State<ShiftEntryScreen> createState() => _ShiftEntryScreenState();
}

class _ShiftEntryScreenState extends State<ShiftEntryScreen> {
  final StorageService _storage = StorageService();
  final Map<String, TextEditingController> _controllers = {};
  // NEW: Store shift types as Strings instead of bools
  final Map<String, String> _shiftTypes = {}; 

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 14; i++) {
      DateTime date = widget.fortnightStart.add(Duration(days: i));
      String key = "${date.year}-${date.month}-${date.day}";
      
      final savedData = _storage.getShift(key);
      _controllers[key] = TextEditingController(
        text: (savedData['hours'] != null && savedData['hours'] > 0) 
            ? savedData['hours'].toString() 
            : '',
      );
      
      // Load the saved type (Ordinary, PM, AL, SL) or default to Ordinary
      _shiftTypes[key] = savedData['type'] ?? 'Ordinary';
    }
  }

  void _saveAll() {
    _controllers.forEach((key, controller) {
      double hours = double.tryParse(controller.text) ?? 0.0;
      String type = _shiftTypes[key] ?? 'Ordinary';

      // FIX: Now sending the String 'type' instead of a bool
      _storage.saveShift(key, hours, type);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shifts saved successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Fortnight Shifts')),
      body: ListView.builder(
        itemCount: 14,
        itemBuilder: (context, index) {
          DateTime date = widget.fortnightStart.add(Duration(days: index));
          String key = "${date.year}-${date.month}-${date.day}";

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(DateFormat('EEE, d MMM').format(date)),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _controllers[key],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: 'Hrs'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButton<String>(
                      value: _shiftTypes[key],
                      isExpanded: true,
                      items: <String>['Ordinary', 'PM', 'AL', 'SL']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _shiftTypes[key] = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ElevatedButton(
          onPressed: _saveAll,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const Text("SAVE AND FINISH"),
        ),
      ),
    );
  }
}