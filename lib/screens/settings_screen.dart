import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  
  late TextEditingController _baseRateController;
  late TextEditingController _pmController;
  late TextEditingController _satController;
  late TextEditingController _sunController;
  late TextEditingController _leaveLoadingController;
  late DateTime _selectedAnchor;
  late bool _taxFreeThreshold; // Renamed to match model

  @override
  void initState() {
    super.initState();
    final settings = _storage.getSettings(); //
    
    _baseRateController = TextEditingController(text: settings.baseRate.toString()); //
    _pmController = TextEditingController(text: (settings.pmLoading * 100).toString()); //
    _satController = TextEditingController(text: (settings.satLoading * 100).toString()); //
    _sunController = TextEditingController(text: (settings.sunLoading * 100).toString()); //
    _leaveLoadingController = TextEditingController(text: (settings.leaveLoading * 100).toString()); //
    _selectedAnchor = settings.anchorDate; //
    _taxFreeThreshold = settings.taxFreeThreshold; // Correct getter name from model
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedAnchor,
      firstDate: DateTime(2024),
      lastDate: DateTime(2101),
    ); //
    if (picked != null && picked != _selectedAnchor) {
      setState(() {
        _selectedAnchor = picked;
      }); //
    }
  }

  void _saveSettings() {
    final updatedSettings = UserSettings(
      baseRate: double.tryParse(_baseRateController.text) ?? 0.0,
      pmLoading: (double.tryParse(_pmController.text) ?? 0.0) / 100,
      satLoading: (double.tryParse(_satController.text) ?? 0.0) / 100,
      sunLoading: (double.tryParse(_sunController.text) ?? 0.0) / 100,
      leaveLoading: (double.tryParse(_leaveLoadingController.text) ?? 0.0) / 100,
      anchorDate: _selectedAnchor,
      taxFreeThreshold: _taxFreeThreshold, // Corrected parameter name
    );

    _storage.saveSettings(updatedSettings); //
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings Saved!')),
    ); //
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("Step 1: Set your Pay Cycle Start", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text("Fortnight Start Date (Anchor)"),
            subtitle: Text(DateFormat('EEEE, d MMM yyyy').format(_selectedAnchor)),
            trailing: const Icon(Icons.calendar_today, color: Colors.blue),
            onTap: _pickDate,
            tileColor: Colors.blue.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
          ), //
          const SizedBox(height: 24),
          const Text("Step 2: Tax Settings", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Claim Tax-Free Threshold'),
            subtitle: const Text('Scale 2 (Enabled) or Scale 1 (Disabled)'),
            secondary: const Icon(Icons.account_balance_wallet, color: Colors.blue),
            value: _taxFreeThreshold,
            onChanged: (bool value) {
              setState(() {
                _taxFreeThreshold = value;
              });
            },
          ),
          const SizedBox(height: 24),
          const Text("Step 3: Set your Pay Rates", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildInput('Base Hourly Rate (\$)', _baseRateController), //
          _buildInput('PM Loading (%)', _pmController), //
          _buildInput('Saturday Loading (%)', _satController), //
          _buildInput('Sunday Loading (%)', _sunController), //
          _buildInput('Leave Loading (AL) (%)', _leaveLoadingController), //
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('SAVE ALL SETTINGS', style: TextStyle(fontSize: 16)),
          ), //
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.attach_money, size: 20),
        ),
      ),
    ); //
  }
}