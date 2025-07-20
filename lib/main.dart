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
      // theme: ThemeData.light(useMaterial3: true).copyWith(
      //   scaffoldBackgroundColor: const Color.fromARGB(255, 231, 231, 231),
      //   cardColor: const Color.fromARGB(255, 200, 200, 200),
      // ),
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF5E548E),
          onPrimary: Colors.white,

          primaryContainer: Color(0x80DFD5E7),

          secondary: Color(0xFFDFD5E7),
          onSecondary: Color(0xFF5E548E),

          error: Colors.red,
          onError: Colors.white,

          surface: Colors.white,
          onSurface: Color(0xFF5E548E),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFDFD5E7),
          toolbarHeight: 45,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Color(0xFF5E548E),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Color(0x80DFD5E7),
            height: 80,
            elevation: 0,

            indicatorColor: const Color(0xFF5E548E),

            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Colors.white);
              } else {
                return IconThemeData(color: Color(0xFF5E548E));
              }
            }
            ),

            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(color: Color(0xFF5E548E), fontWeight: FontWeight.bold);
              } else {
                return TextStyle(color: const Color(0xFF5E548E));
              }
            }
            )
        ),
      ),
      debugShowCheckedModeBanner: false,

      home: const HomeWrapper(),
    );
  }
}