import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

import 'providers/auth_provider.dart';
import 'providers/leave_provider.dart';
import 'routes/app_router.dart';
import 'config/supabase_config.dart'; // Import SupabaseConfig

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the .env file
  await dotenv.load();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const SmartLeaveApp());
}

class SmartLeaveApp extends StatelessWidget {
  const SmartLeaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
      ],
      child: MaterialApp.router(
        title: 'SmartLeave',
        routerConfig: AppRouter(authProvider).router,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
      ),
    );
  }
}
