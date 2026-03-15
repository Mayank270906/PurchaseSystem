/// Purchase Registry Mobile Application
/// 
/// Entry point with Material 3 theming, Provider state management,
/// and role-based navigation routing.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/user/purchase_entry_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const PurchaseRegistryApp(),
    ),
  );
}

class PurchaseRegistryApp extends StatelessWidget {
  const PurchaseRegistryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purchase Registry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3F51B5), // Indigo
        brightness: Brightness.light,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// AuthGate decides which screen to show based on login state and role
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        // If not logged in, show login screen
        if (!auth.isLoggedIn) {
          return const LoginScreen();
        }

        // Route based on user role
        switch (auth.currentUser?.role) {
          case 'admin':
            return const AdminDashboard();
          case 'manager':
            return const ManagerDashboard();
          case 'user':
            return const PurchaseEntryScreen();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
