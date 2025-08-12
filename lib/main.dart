// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memoir/providers/cloud_provider.dart';
import 'package:memoir/screens/home_wrapper.dart';
import 'package:memoir/screens/notification/notification_screen.dart';
import 'package:memoir/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_10y.dart' as tz;

// Supabase Credentials from CloudNote
const SUPABASE_URL = 'https://uonjdjehvwdhyaegbfer.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvbmpkamVodndkaHlhZWdiZmVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzMzU3NDksImV4cCI6MjA2NjkxMTc0OX0.Tdese3XxHx9wi8ZxE2-gwNV0NFvKY_GZyuttak5Qelo';


/// This class handles the eager initialization of providers that depend on auth state.
class ProviderInitializer {
  final ProviderContainer container;

  ProviderInitializer(this.container);

  void setup() {
    // Listen for auth changes to initialize providers when a user signs in.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        container.read(cloudNotifierProvider);
      }
    });
  }
}

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

  // Create a ProviderContainer to manage our providers' state.
  final container = ProviderContainer();

  // Setup the initializer to listen for auth changes.
  ProviderInitializer(container).setup();

  // **CRITICAL:** Handle the case where the app starts with a user already logged in.
  // The onAuthStateChange stream only fires on *changes*, so we need this
  // initial check for cold starts.
  if (Supabase.instance.client.auth.currentSession != null) {
    container.read(cloudNotifierProvider);
  }
   
  // Use UncontrolledProviderScope to pass our pre-configured container to the app.
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
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
          primary: const Color(0xFF5C29A2),
          onPrimary: Colors.white,

          primaryContainer: const Color(0x33DFD5E7),

          secondary: const Color(0xFFF3E8F5),
          onSecondary: const Color(0xFF5C29A2),

          error: Colors.red,
          onError: Colors.white,

          surface: Colors.white,
          onSurface: const Color(0xFF5C29A2),

          outline: Color(0xFFE2D1F9),
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF3E8F5),
          toolbarHeight: 45,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Color(0xFF5C29A2),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFFF3E8F5),
            height: 80,
            elevation: 0,

            indicatorColor: const Color(0xFF5C29A2),

            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Colors.white);
              } else {
                return IconThemeData(color: const Color(0xFF5C29A2));
              }
            }
            ),

            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(color: Color(0xFF5C29A2), fontWeight: FontWeight.bold);
              } else {
                return const TextStyle(color: Color(0xFF5C29A2));
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