// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_admin/screens/dashboard/dashboard_shell.dart';
import 'package:flutter_admin/screens/login/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/admin_auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/notification_provider.dart'; 

import 'services/admin_auth_service.dart';
import 'services/user_management_service.dart';
import 'services/feedback_service.dart';
import 'services/notification_service.dart'; 

import 'screens/login/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final supabase = Supabase.instance.client;
  final adminAuthService = AdminAuthService(supabase);
  final userManagementService = UserManagementService(supabase);
  final feedbackService = FeedbackService(supabase);
  final notificationService =
      NotificationService(supabase); 

  runApp(
    MyApp(
      adminAuthService: adminAuthService,
      userManagementService: userManagementService,
      feedbackService: feedbackService,
      notificationService: notificationService, 
    ),
  );
}

class MyApp extends StatelessWidget {
  final AdminAuthService adminAuthService;
  final UserManagementService userManagementService;
  final FeedbackService feedbackService;
  final NotificationService notificationService; 

  const MyApp({
    super.key,
    required this.adminAuthService,
    required this.userManagementService,
    required this.feedbackService,
    required this.notificationService, 
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AdminAuthProvider(adminAuthService),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(userManagementService),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              FeedbackProvider(feedbackService, userManagementService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationService),
        ),
      ],
      child: MaterialApp(
        title: 'Memoir Admin',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}