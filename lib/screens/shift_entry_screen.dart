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
      
      _shiftTypes[key] = savedData['type'] ?? 'Ordinary';
    }
  }

  void _saveAll() {
    _controllers.forEach((key, controller) {
      double hours = double.tryParse(controller.text) ?? 0.0;
      String type = _shiftTypes[key] ?? 'Ordinary';

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
      appBar: AppBar(
        title: const Text('Edit Fortnight Shifts'),
        // ✅ Action moved to Top Right
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Shifts',
            onPressed: _saveAll,
          ),
          const SizedBox(width: 8), // Give the icon a little breathing room
        ],
      ),
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
                    child: Text(
                      DateFormat('EEE, d MMM').format(date),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _controllers[key],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'Hrs',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButton<String>(
                      value: _shiftTypes[key],
                      isExpanded: true,
                      underline: Container(), // Cleans up the look inside the card
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
      // ✅ Removed bottomNavigationBar for a cleaner UI
    );
  }
}
