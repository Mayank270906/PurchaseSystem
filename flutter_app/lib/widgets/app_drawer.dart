/// App Drawer Widget
/// 
/// Side navigation drawer with role-aware menu items.
/// Shows different options based on user role.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/change_password_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          // Header with user info
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              user?.username ?? 'User',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.username ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            otherAccountsPictures: [
              Chip(
                label: Text(
                  (user?.role ?? 'user').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.white24,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (user?.isAdmin == true) ...[
                  _buildNavItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    route: '/admin',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.people,
                    title: 'Manage Users',
                    route: '/admin/users',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.inventory,
                    title: 'Manage Items',
                    route: '/admin/items',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.store,
                    title: 'Manage Vendors',
                    route: '/admin/vendors',
                  ),
                ],
                if (user?.isManager == true) ...[
                  _buildNavItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    route: '/manager',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.payment,
                    title: 'Record Payment',
                    route: '/manager/payments',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.store,
                    title: 'Vendors',
                    route: '/manager/vendors',
                  ),
                ],
                if (user?.isUser == true)
                  _buildNavItem(
                    context,
                    icon: Icons.add_shopping_cart,
                    title: 'Record Purchase',
                    route: '/user/purchase',
                  ),
              ],
            ),
          ),

          // Change Password
          const Divider(),
          ListTile(
            leading: Icon(Icons.lock_reset, color: colorScheme.primary),
            title: const Text('Change Password'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),

          // Logout button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Close drawer
        // Navigate if needed — for now screens are embedded
      },
    );
  }
}
