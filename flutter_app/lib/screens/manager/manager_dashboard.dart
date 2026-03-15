/// Manager Dashboard Screen
/// 
/// Shows financial overview and navigation:
/// - Summary cards: Total Purchases, Total Payments, Pending
/// - Recent purchases table with filters
/// - Quick actions for payments and vendor profiles

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/purchase.dart';
import '../../widgets/app_drawer.dart';
import 'payment_entry_screen.dart';
import 'vendor_profile_screen.dart';
import 'price_management_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  Map<String, dynamic> _summary = {};
  List<dynamic> _vendorBalances = [];
  List<Purchase> _recentPurchases = [];
  bool _isLoading = true;
  int _currentTab = 0;

  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final summary = await ApiService.getDashboardSummary();
      final balances = await ApiService.getVendorBalances();
      final purchasesData = await ApiService.getPurchases(limit: 20);
      final purchases = (purchasesData['purchases'] as List?)
              ?.map((json) => Purchase.fromJson(json))
              .toList() ??
          [];

      setState(() {
        _summary = summary;
        _vendorBalances = balances;
        _recentPurchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Financial summary cards
                    _buildSummaryCards(colorScheme),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),

                    // Toggle: Vendor Balances / Recent Purchases
                    Row(
                      children: [
                        _buildTabButton('Vendor Balances', 0),
                        const SizedBox(width: 8),
                        _buildTabButton('Recent Purchases', 1),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_currentTab == 0)
                      _buildVendorBalances()
                    else
                      _buildRecentPurchases(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards(ColorScheme colorScheme) {
    final totalPurchases = (_summary['total_purchases'] ?? 0).toDouble();
    final totalPayments = (_summary['total_payments'] ?? 0).toDouble();
    final pending = (_summary['pending_payments'] ?? 0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Purchases',
                value: currencyFormat.format(totalPurchases),
                icon: Icons.shopping_cart,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Total Payments',
                value: currencyFormat.format(totalPayments),
                icon: Icons.payment,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          title: 'Pending Payments',
          value: currencyFormat.format(pending),
          icon: Icons.pending_actions,
          color: pending > 0 ? Colors.red : Colors.green,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.payment,
            label: 'Record\nPayment',
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentEntryScreen()),
            ).then((_) => _loadDashboard()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.price_change,
            label: 'Manage\nPrices',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PriceManagementScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.store,
            label: 'Vendor\nProfiles',
            color: Colors.purple,
            onTap: () => _showVendorList(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVendorBalances() {
    if (_vendorBalances.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No vendor data available')),
      );
    }

    return Column(
      children: _vendorBalances.map((vb) {
        final pending = double.parse(vb['pending_balance'].toString());
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: pending > 0
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              child: Icon(
                pending > 0 ? Icons.warning : Icons.check_circle,
                color: pending > 0 ? Colors.red : Colors.green,
              ),
            ),
            title: Text(
              vb['vendor_name'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Purchased: ${currencyFormat.format(double.parse(vb['total_purchases'].toString()))} | '
              'Paid: ${currencyFormat.format(double.parse(vb['total_payments'].toString()))}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Pending', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  currencyFormat.format(pending),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: pending > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VendorProfileScreen(vendorId: vb['vendor_id']),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentPurchases() {
    if (_recentPurchases.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No purchases recorded yet')),
      );
    }

    return Column(
      children: _recentPurchases.map((p) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shopping_bag, color: Colors.blue.shade700),
            ),
            title: Text(
              '${p.itemName ?? 'Item'} × ${p.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${p.vendorName ?? 'Vendor'} • ${_formatDate(p.datetime)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              p.totalAmount != null
                  ? currencyFormat.format(p.totalAmount)
                  : '—',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(String datetime) {
    try {
      final date = DateTime.parse(datetime);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return datetime;
    }
  }

  void _showVendorList(BuildContext context) async {
    try {
      final vendors = await ApiService.getVendors();
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Vendor',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: vendors.length,
                  itemBuilder: (context, index) {
                    final v = vendors[index];
                    return ListTile(
                      leading: const Icon(Icons.store),
                      title: Text(v['vendor_name']),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VendorProfileScreen(vendorId: v['id']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vendors: $e')),
        );
      }
    }
  }
}

// ─── Summary Card Widget ────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: fullWidth ? 28 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action Button Widget ─────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
