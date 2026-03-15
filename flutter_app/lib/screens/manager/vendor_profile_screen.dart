/// Vendor Profile Screen (Manager)
/// 
/// Shows complete vendor information with tabs:
/// - Info: vendor details
/// - Price List: vendor-specific item prices (editable)
/// - Purchases: purchase history for this vendor
/// - Payments: payment history for this vendor
/// - Financial summary at the top

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class VendorProfileScreen extends StatefulWidget {
  final int vendorId;
  const VendorProfileScreen({super.key, required this.vendorId});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getVendorProfile(widget.vendorId);
      setState(() {
        _profile = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?['vendor']?['vendor_name'] ?? 'Vendor Profile'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Price List'),
            Tab(text: 'Purchases'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load vendor profile'))
              : Column(
                  children: [
                    // Financial summary bar
                    _buildFinancialSummary(),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInfoTab(),
                          _buildPriceListTab(),
                          _buildPurchasesTab(),
                          _buildPaymentsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFinancialSummary() {
    final summary = _profile?['financial_summary'] ?? {};
    final totalPurchases = (summary['total_purchases'] ?? 0).toDouble();
    final totalPayments = (summary['total_payments'] ?? 0).toDouble();
    final pending = (summary['pending_balance'] ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          _FinancialChip(
            label: 'Purchases',
            value: currencyFormat.format(totalPurchases),
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _FinancialChip(
            label: 'Payments',
            value: currencyFormat.format(totalPayments),
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _FinancialChip(
            label: 'Pending',
            value: currencyFormat.format(pending),
            color: pending > 0 ? Colors.red : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final vendor = _profile?['vendor'] ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(icon: Icons.store, label: 'Name', value: vendor['vendor_name'] ?? '—'),
        _InfoTile(icon: Icons.phone, label: 'Phone', value: vendor['phone'] ?? '—'),
        _InfoTile(icon: Icons.location_on, label: 'Address', value: vendor['address'] ?? '—'),
        _InfoTile(icon: Icons.note, label: 'Notes', value: vendor['notes'] ?? '—'),
        _InfoTile(
          icon: Icons.calendar_today,
          label: 'Created',
          value: _formatDate(vendor['created_at'] ?? ''),
        ),
      ],
    );
  }

  Widget _buildPriceListTab() {
    final prices = _profile?['price_list'] as List? ?? [];

    if (prices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.price_change_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No prices set for this vendor'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prices.length,
      itemBuilder: (context, index) {
        final p = prices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory, color: Colors.orange.shade700),
            ),
            title: Text(
              p['item_name'] ?? 'Item',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Updated by: ${p['updated_by'] ?? '—'}'),
            trailing: Text(
              currencyFormat.format(double.parse(p['price'].toString())),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            onTap: () => _showEditPriceDialog(p),
          ),
        );
      },
    );
  }

  Widget _buildPurchasesTab() {
    final purchases = _profile?['purchases'] as List? ?? [];

    if (purchases.isEmpty) {
      return const Center(child: Text('No purchases recorded'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final p = purchases[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              '${p['item_name']} × ${p['quantity']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${_formatDate(p['datetime'] ?? '')} • By: ${p['recorded_by'] ?? '—'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              currencyFormat.format(double.parse((p['total_amount'] ?? 0).toString())),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    final payments = _profile?['payments'] as List? ?? [];

    if (payments.isEmpty) {
      return const Center(child: Text('No payments recorded'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final p = payments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.payment, color: Colors.green.shade700),
            ),
            title: Text(
              currencyFormat.format(double.parse(p['amount'].toString())),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p['purpose'] != null) Text(p['purpose']),
                Text(
                  '${p['payment_method'] ?? 'Cash'} • ${_formatDate(p['datetime'] ?? '')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditPriceDialog(Map<String, dynamic> priceRecord) {
    final controller = TextEditingController(
      text: double.parse(priceRecord['price'].toString()).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${priceRecord['item_name']} Price'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'New Price (₹)',
            prefixIcon: Icon(Icons.currency_rupee),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final price = double.tryParse(controller.text);
              if (price == null || price < 0) return;

              try {
                await ApiService.setVendorPrice(
                  vendorId: widget.vendorId,
                  itemId: priceRecord['item_id'],
                  price: price,
                );
                if (context.mounted) Navigator.pop(context);
                _loadProfile();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
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
}

// ─── Helper Widgets ─────────────────────────────────────

class _FinancialChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FinancialChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
