/// Manage Vendors Screen (Admin)
/// 
/// Admin can create and edit vendor profiles.

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/vendor.dart';

class ManageVendorsScreen extends StatefulWidget {
  const ManageVendorsScreen({super.key});

  @override
  State<ManageVendorsScreen> createState() => _ManageVendorsScreenState();
}

class _ManageVendorsScreenState extends State<ManageVendorsScreen> {
  List<Vendor> _vendors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getVendors();
      setState(() {
        _vendors = data.map((json) => Vendor.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vendors: $e')),
        );
      }
    }
  }

  void _showVendorDialog({Vendor? vendor}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: vendor?.vendorName ?? '');
    final phoneCtrl = TextEditingController(text: vendor?.phone ?? '');
    final addressCtrl = TextEditingController(text: vendor?.address ?? '');
    final notesCtrl = TextEditingController(text: vendor?.notes ?? '');
    final isEditing = vendor != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Vendor' : 'Add New Vendor'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vendor Name',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                if (isEditing) {
                  await ApiService.updateVendor(vendor.id, {
                    'vendor_name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'notes': notesCtrl.text.trim(),
                  });
                } else {
                  await ApiService.createVendor(
                    vendorName: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty
                        ? null
                        : phoneCtrl.text.trim(),
                    address: addressCtrl.text.trim().isEmpty
                        ? null
                        : addressCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  );
                }
                if (context.mounted) Navigator.pop(context);
                _loadVendors();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing
                          ? 'Vendor updated!'
                          : 'Vendor created!'),
                    ),
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
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vendors'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVendorDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Vendor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVendors,
              child: _vendors.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No vendors found', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vendors.length,
                      itemBuilder: (context, index) {
                        final vendor = _vendors[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.store, color: Colors.orange),
                            ),
                            title: Text(
                              vendor.vendorName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (vendor.phone != null)
                                  Text('📞 ${vendor.phone}'),
                                if (vendor.address != null)
                                  Text('📍 ${vendor.address}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showVendorDialog(vendor: vendor),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
