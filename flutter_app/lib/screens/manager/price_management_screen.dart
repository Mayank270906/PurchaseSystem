/// Price Management Screen (Manager)
/// 
/// Allows managers to set/update item prices for each vendor.
/// 1. Select a vendor
/// 2. View current price list
/// 3. Add or edit prices for items

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/vendor.dart';
import '../../models/item.dart';
import '../../models/vendor_price.dart';

class PriceManagementScreen extends StatefulWidget {
  const PriceManagementScreen({super.key});

  @override
  State<PriceManagementScreen> createState() => _PriceManagementScreenState();
}

class _PriceManagementScreenState extends State<PriceManagementScreen> {
  List<Vendor> _vendors = [];
  List<Item> _allItems = [];
  List<VendorPrice> _prices = [];
  Vendor? _selectedVendor;
  bool _isLoading = true;
  bool _loadingPrices = false;

  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final vendors = await ApiService.getVendors();
      final items = await ApiService.getItems();
      setState(() {
        _vendors = vendors.map((json) => Vendor.fromJson(json)).toList();
        _allItems = items.map((json) => Item.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVendorPrices(int vendorId) async {
    setState(() => _loadingPrices = true);
    try {
      final data = await ApiService.getVendorPrices(vendorId);
      setState(() {
        _prices = data.map((json) => VendorPrice.fromJson(json)).toList();
        _loadingPrices = false;
      });
    } catch (e) {
      setState(() => _loadingPrices = false);
    }
  }

  void _showSetPriceDialog({VendorPrice? existingPrice}) {
    Item? selectedItem;
    final priceCtrl = TextEditingController(
      text: existingPrice?.price.toString() ?? '',
    );

    // Get items that don't have a price set yet
    final existingItemIds = _prices.map((p) => p.itemId).toSet();
    final availableItems = existingPrice != null
        ? _allItems
        : _allItems.where((i) => !existingItemIds.contains(i.id)).toList();

    if (existingPrice != null) {
      selectedItem = _allItems.where((i) => i.id == existingPrice.itemId).firstOrNull;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingPrice != null ? 'Edit Price' : 'Set Item Price'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existingPrice == null)
                DropdownButtonFormField<Item>(
                  decoration: const InputDecoration(
                    labelText: 'Select Item',
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  items: availableItems.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item.itemName),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedItem = v),
                )
              else
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Item',
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  child: Text(existingPrice.itemName),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final itemId = existingPrice?.itemId ?? selectedItem?.id;
                final price = double.tryParse(priceCtrl.text);

                if (itemId == null || price == null || price < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields correctly')),
                  );
                  return;
                }

                try {
                  await ApiService.setVendorPrice(
                    vendorId: _selectedVendor!.id,
                    itemId: itemId,
                    price: price,
                  );
                  if (context.mounted) Navigator.pop(context);
                  _loadVendorPrices(_selectedVendor!.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Price updated!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Prices'),
        centerTitle: true,
      ),
      floatingActionButton: _selectedVendor != null
          ? FloatingActionButton.extended(
              onPressed: () => _showSetPriceDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Price'),
            )
          : null,
      body: Column(
        children: [
          // Vendor selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<Vendor>(
              decoration: const InputDecoration(
                labelText: 'Select Vendor',
                prefixIcon: Icon(Icons.store),
              ),
              items: _vendors.map((v) {
                return DropdownMenuItem(
                  value: v,
                  child: Text(v.vendorName),
                );
              }).toList(),
              onChanged: (v) {
                setState(() => _selectedVendor = v);
                if (v != null) _loadVendorPrices(v.id);
              },
            ),
          ),

          // Price list
          Expanded(
            child: _selectedVendor == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Select a vendor to view prices',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _loadingPrices
                    ? const Center(child: CircularProgressIndicator())
                    : _prices.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.price_change_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No prices set for this vendor'),
                                SizedBox(height: 8),
                                Text(
                                  'Tap + to add item prices',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _prices.length,
                            itemBuilder: (context, index) {
                              final p = _prices[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.inventory,
                                        color: Colors.orange.shade700),
                                  ),
                                  title: Text(
                                    p.itemName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: p.updatedBy != null
                                      ? Text('Updated by: ${p.updatedBy}',
                                          style: const TextStyle(fontSize: 12))
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currencyFormat.format(p.price),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () =>
                                            _showSetPriceDialog(existingPrice: p),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
