// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/party_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AddPartyScreen extends StatefulWidget {
  final PartyType initialType;

  const AddPartyScreen({
    super.key,
    this.initialType = PartyType.customer,
  });

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _openingBalanceController;

  late PartyType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _openingBalanceController = TextEditingController(text: '0');
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _pickFromContacts() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission is required to pick a contact.')),
        );
      }
      return;
    }

    try {
      List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ContactsPickerSheet(
          contacts: contacts,
          onSelectContact: (contact) {
            final name = contact.displayName;
            String phone = '';
            if (contact.phones.isNotEmpty) {
              phone = contact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '');
              if (phone.length > 10) {
                phone = phone.substring(phone.length - 10);
              }
            }

            setState(() {
              _nameController.text = name;
              if (phone.isNotEmpty) _phoneController.text = phone;
            });
            Navigator.of(ctx).pop();
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load contacts: $e')),
        );
      }
    }
  }

  Future<void> _saveParty() async {
    if (!_formKey.currentState!.validate()) return;

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final double bal = double.tryParse(_openingBalanceController.text.trim()) ?? 0.0;

    final newParty = Party(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      type: _selectedType,
      openingBalance: bal,
    );

    final result = await dbService.addParty(newParty, isGuest: authService.isGuestMode);

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Party "${newParty.name}" added successfully!'),
            backgroundColor: AppConstants.cashInColor,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add party: ${dbService.errorMessage ?? "Database error"}'),
            backgroundColor: AppConstants.accentColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedType == PartyType.supplier ? 'Add Supplier' : 'Add Customer'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Pick Options Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.contacts_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Quick Import from Contacts',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Import name and phone directly from phonebook',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _pickFromContacts,
                      child: const Text('Import', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Party / Business Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Party / Business Name *',
                  hintText: 'e.g. Ramesh Hardware',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '10-digit mobile number',
                  prefixIcon: const Icon(Icons.phone_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Phone number is required';
                  if (val.trim().length != 10) return 'Must be 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Party Type Selector
              const Text('Party Role / Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<PartyType>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: const [
                  DropdownMenuItem(value: PartyType.customer, child: Text('Customer (Receivable)')),
                  DropdownMenuItem(value: PartyType.supplier, child: Text('Supplier (Payable)')),
                  DropdownMenuItem(value: PartyType.both, child: Text('Both Customer & Supplier')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 20),

              // Opening Balance
              TextFormField(
                controller: _openingBalanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Opening Balance (${AppConstants.currencySymbol})',
                  hintText: '+ for Receivable, - for Payable',
                  prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveParty,
                  child: const Text('SAVE PARTY ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactsPickerSheet extends StatefulWidget {
  final List<Contact> contacts;
  final ValueChanged<Contact> onSelectContact;

  const _ContactsPickerSheet({
    required this.contacts,
    required this.onSelectContact,
  });

  @override
  State<_ContactsPickerSheet> createState() => _ContactsPickerSheetState();
}

class _ContactsPickerSheetState extends State<_ContactsPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = widget.contacts.where((c) {
      final name = c.displayName.toLowerCase();
      final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
      return name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Text('Select Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search contacts by name or number...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No contacts found'))
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, idx) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final c = filtered[idx];
                      final phone = c.phones.isNotEmpty ? c.phones.first.number : 'No number';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppConstants.primaryColor.withOpacity(0.15),
                          child: Text(
                            c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                          ),
                        ),
                        title: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(phone),
                        onTap: () => widget.onSelectContact(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
