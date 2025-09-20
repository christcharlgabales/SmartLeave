// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your providers and screens
import 'providers/auth_provider.dart';
import 'providers/leave_provider.dart';  // Add this import
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://igwvqebnplzvtapuxlqy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlnd3ZxZWJucGx6dnRhcHV4bHF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzODYxNzUsImV4cCI6MjA3Mzk2MjE3NX0.hdjOW-mXLnN2zB4MaCQVFEo_mdcO30VUBZ7510Mqm2w',
  );

  runApp(const SmartLeaveApp());
}

class SmartLeaveApp extends StatelessWidget {
  const SmartLeaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create AuthProvider instance
    final authProvider = AuthProvider();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => LeaveProvider()), // Add LeaveProvider
        // Add other providers here as needed
      ],
      child: MaterialApp.router(
        title: 'SmartLeave',
        routerConfig: AppRouter(authProvider).router, // Pass authProvider to AppRouter
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
      ),
    );
  }
}