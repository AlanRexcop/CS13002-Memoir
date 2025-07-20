// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memoir/screens/home_wrapper.dart';
import 'package:memoir/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_10y.dart' as tz;

// Supabase Credentials from CloudNote
const SUPABASE_URL = 'https://uonjdjehvwdhyaegbfer.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvbmpkamVodndkaHlhZWdiZmVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzMzU3NDksImV4cCI6MjA2NjkxMTc0OX0.Tdese3XxHx9wi8ZxE2-gwNV0NFvKY_GZyuttak5Qelo';


Future<void> main() async {
  // Ensure Flutter is ready.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );
  
  // Initialize Memoir-specific services
  tz.initializeTimeZones();
  await initializeDateFormatting();
  await NotificationService().init();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memoir',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 231, 231, 231),
        cardColor: const Color.fromARGB(255, 200, 200, 200),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeWrapper(),
    );
  }
}