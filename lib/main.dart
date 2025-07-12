// C:\dev\memoir\lib\main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memoir/screens/home_wrapper.dart';
import 'package:memoir/services/notification_service.dart';
import 'package:timezone/data/latest_10y.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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