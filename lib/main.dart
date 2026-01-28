import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Add this
import 'screens/dashboard_screen.dart';

void main() async {
  // 1. Initialize Hive
  await Hive.initFlutter();
  
  // 2. Open the boxes we use in StorageService
  await Hive.openBox('settings');
  await Hive.openBox('shifts');
  
  runApp(const ShiftPayApp());
}

class ShiftPayApp extends StatelessWidget {
  const ShiftPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShiftPay',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}