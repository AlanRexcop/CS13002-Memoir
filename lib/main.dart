// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_admin/screens/dashboard/dashboard_shell.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/admin_auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/feedback_provider.dart';
import 'services/admin_auth_service.dart';
import 'services/user_management_service.dart';
import 'screens/login/auth_gate.dart';
import 'services/feedback_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // It's a good practice to create service instances here
  // to avoid creating them multiple times.
  final supabase = Supabase.instance.client;
  final adminAuthService = AdminAuthService(supabase);
  final userManagementService = UserManagementService(supabase);
  final feedbackService = FeedbackService(supabase);

  runApp(
    MyApp(
      adminAuthService: adminAuthService,
      userManagementService: userManagementService,
      feedbackService: feedbackService,
    ),
  );
}

class MyApp extends StatelessWidget {
  // Accept the services in the constructor
  final AdminAuthService adminAuthService;
  final UserManagementService userManagementService;
  final FeedbackService feedbackService;

  const MyApp({
    super.key,
    required this.adminAuthService,
    required this.userManagementService,
    required this.feedbackService,
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
        // Now, we can pass both required services to the FeedbackProvider
        ChangeNotifierProvider(
          create: (_) =>
              FeedbackProvider(feedbackService, userManagementService),
        ),
      ],
      child: MaterialApp(
        title: 'Memoir Admin',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: const DashboardShell(),
      ),
    );
  }
}
