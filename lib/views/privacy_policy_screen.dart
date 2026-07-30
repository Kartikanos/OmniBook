// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../core/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy & DPDP Compliance'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DPDP Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.gavel_rounded, color: AppConstants.primaryColor, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DPDP Act 2023 Compliant',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.primaryColor),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Digital Personal Data Protection Act (India)',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('1. Overview'),
            _buildSectionBody(
              'OmniBook is committed to protecting your business data and respecting your privacy in strict accordance with India\'s Digital Personal Data Protection (DPDP) Act 2023.',
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('2. Phonebook & Contacts Permission'),
            _buildSectionBody(
              '• Read-Only Access: When you choose to "Import from Contacts", OmniBook requests contact access solely to allow you to select a party or supplier.\n'
              '• User-Selected Only: We do NOT upload your entire phonebook or store unselected contacts on any remote server.\n'
              '• Purpose Limitation: Selected names and phone numbers are strictly used within your local ledger for transaction tracking and receipt generation.',
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('3. Data Storage & Security'),
            _buildSectionBody(
              'Your ledger data, transaction logs, and inventory items are encrypted in transit and at rest using industry-standard AES-256 protocols via Supabase Cloud PostgreSQL infrastructure.',
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('4. Data Principal Rights'),
            _buildSectionBody(
              'Under the DPDP Act 2023, you retain full rights to:\n'
              '• Access and review your business records.\n'
              '• Correct, update, or erase party accounts and inventory items at any time.\n'
              '• Export your ledger summaries as encrypted PDF documents.',
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('5. Contact Data Fiduciary'),
            _buildSectionBody(
              'For privacy queries, data access requests, or grievance redressal, please contact our Data Governance team at privacy@omnibook.app.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSectionBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.grey),
      ),
    );
  }
}
