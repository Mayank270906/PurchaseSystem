/// Payment Entry Screen (Manager)
/// 
/// Form for recording payments made to vendors.
/// Fields: Vendor, Amount, Purpose, Payment Method, Notes

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/vendor.dart';
import '../../widgets/searchable_dropdown.dart';

class PaymentEntryScreen extends StatefulWidget {
  const PaymentEntryScreen({super.key});

  @override
  State<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends State<PaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  List<Vendor> _vendors = [];
  Vendor? _selectedVendor;
  String _paymentMethod = 'Cash';
  bool _isLoading = true;
  bool _isSubmitting = false;

  final _paymentMethods = ['Cash', 'Bank Transfer', 'UPI', 'Cheque', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    try {
      final data = await ApiService.getVendors();
      setState(() {
        _vendors = data.map((json) => Vendor.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vendor.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.recordPayment(
        vendorId: _selectedVendor!.id,
        amount: double.parse(_amountController.text),
        purpose: _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        if (response['payment'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment recorded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.payment, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'New Payment',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Record a payment made to a vendor',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor selection
                  SearchableDropdown<Vendor>(
                    label: 'Vendor',
                    hintText: 'Search vendor...',
                    items: _vendors,
                    displayStringFor: (v) => v.vendorName,
                    value: _selectedVendor,
                    onChanged: (v) => setState(() => _selectedVendor = v),
                  ),
                  const SizedBox(height: 20),

                  // Amount
                  Text(
                    'Amount (₹)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Enter amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Purpose
                  Text(
                    'Purpose',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Cement purchase',
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment Method
                  Text(
                    'Payment Method',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(value: method, child: Text(method));
                    }).toList(),
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  Text(
                    'Notes (optional)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Additional notes...',
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submitPayment,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _isSubmitting ? 'Recording...' : 'Record Payment',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
