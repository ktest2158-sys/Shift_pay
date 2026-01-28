import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings_model.dart';

class StorageService {
  // Accessing the Hive boxes for settings and shift data
  final _settingsBox = Hive.box('settings'); //
  final _shiftsBox = Hive.box('shifts'); //

  /// Saves a shift with the specified date key, hours, and shift type.
  /// Type can be 'Ordinary', 'PM', 'AL', or 'SL'.
  void saveShift(String key, double hours, String type) {
    _shiftsBox.put(key, {
      'hours': hours,
      'type': type,
    }); //
  }

  /// Retrieves shift data for a specific date. 
  /// Returns a Map with default values if no data exists.
  Map<String, dynamic> getShift(String key) {
    final data = _shiftsBox.get(key); //
    if (data != null) {
      return Map<String, dynamic>.from(data); //
    }
    return {'hours': 0.0, 'type': 'Ordinary'}; //
  }

  /// Saves the user's pay rates and anchor date settings.
  void saveSettings(UserSettings settings) {
    _settingsBox.put('user_settings', settings.toMap()); //
  }

  /// Retrieves the saved user settings.
  /// Provides a fallback default if nothing is saved yet.
  UserSettings getSettings() {
    final data = _settingsBox.get('user_settings'); //
    if (data != null) {
      return UserSettings.fromMap(data); //
    }
    // Default fallback anchor date is today
    return UserSettings(anchorDate: DateTime.now()); //
  }

  // --- NEW MANUAL OVERRIDE FUNCTIONS ---

  /// Saves a locked manual dollar amount for leave loading for a specific fortnight.
  void saveManualLoading(String key, double amount) {
    _shiftsBox.put(key, amount); //
  }

  /// Retrieves the locked manual amount. Returns null if no override exists.
  double? getManualLoading(String key) {
    final data = _shiftsBox.get(key); //
    if (data is double) {
      return data; //
    }
    return null; //
  }

  /// Saves a locked manual tax amount for a specific fortnight.
  void saveManualTax(String key, double amount) {
    _shiftsBox.put(key, amount);
  }

  /// Retrieves the locked manual tax. Returns null if no override exists.
  double? getManualTax(String key) {
    final data = _shiftsBox.get(key);
    if (data is double) {
      return data;
    }
    return null;
  }
}