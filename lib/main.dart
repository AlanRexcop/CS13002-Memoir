// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Import the package
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/admin_auth_provider.dart';
import 'providers/user_provider.dart';
import 'services/admin_auth_service.dart';
import 'services/user_management_service.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load the .env file
  await dotenv.load(fileName: ".env");

  // 3. Initialize Supabase with variables from dotenv
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider(AdminAuthService(supabase))),
        ChangeNotifierProvider(create: (_) => UserProvider(UserManagementService(supabase))),
      ],
      child: MaterialApp(
        title: 'Memoir Admin',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false, // Optional: for cleaner UI
        home: const AuthGate(),
      ),
    );
  }
}