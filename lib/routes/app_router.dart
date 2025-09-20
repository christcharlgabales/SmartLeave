// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/leave/request_leave_screen.dart';
import '../screens/leave/my_requests_screen.dart';
import '../screens/leave/team_requests_screen.dart';
import '../screens/leave/calendar_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: authProvider,
    redirect: _handleRedirect,
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),

      // Main App Routes (Protected)
      ShellRoute(
        builder: (context, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/request-leave',
            name: 'request-leave',
            builder: (context, state) => const RequestLeaveScreen(),
          ),
          GoRoute(
            path: '/my-requests',
            name: 'my-requests',
            builder: (context, state) => const MyRequestsScreen(),
          ),
          GoRoute(
            path: '/team-requests',
            name: 'team-requests',
            builder: (context, state) => const TeamRequestsScreen(),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = authProvider.isAuthenticated;
    final isOnSplash = state.matchedLocation == '/splash';
    final isOnAuth = state.matchedLocation == '/login' || 
                     state.matchedLocation == '/signup';

    // If on splash, stay there temporarily
    if (isOnSplash) {
      return null;
    }

    // If not authenticated and not on auth pages, redirect to login
    if (!isAuthenticated && !isOnAuth) {
      return '/login';
    }

    // If authenticated and on auth pages, redirect to dashboard
    if (isAuthenticated && isOnAuth) {
      return '/dashboard';
    }

    // No redirect needed
    return null;
  }
}