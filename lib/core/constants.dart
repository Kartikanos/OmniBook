import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'OmniBook';
  
  // Supabase Table Names
  static const String profilesTable = 'profiles';
  static const String cashEntriesTable = 'cashbook_entries';
  static const String inventoryTable = 'inventory_items';
  static const String ledgersTable = 'ledgers';

  // Colors
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryAccent = Color(0xFF818CF8);
  static const Color secondaryColor = Color(0xFF0EA5E9); // Sky blue
  static const Color accentColor = Color(0xFFF43F5E); // Rose
  
  static const Color cashInColor = Color(0xFF10B981); // Emerald Green
  static const Color cashOutColor = Color(0xFFEF4444); // Red

  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color textDark = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF0F172A);
  static const Color textMutedLight = Color(0xFF64748B);

  // Currency Formatting (Indian Rupee ₹)
  static const String currencySymbol = '₹';

  static String formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Indian Numbering System formatting (e.g. 1,25,000 or 1,250)
    String formattedInt = integerPart;
    if (integerPart.length > 3) {
      final lastThree = integerPart.substring(integerPart.length - 3);
      final remaining = integerPart.substring(0, integerPart.length - 3);
      final regExp = RegExp(r'(\d+?)(?=(\d{2})+(?!\d))');
      final formattedRemaining = remaining.replaceAllMapped(regExp, (Match m) => '${m[1]},');
      formattedInt = '$formattedRemaining,$lastThree';
    }

    final sign = isNegative ? '-' : '';
    return '$sign$currencySymbol $formattedInt.$decimalPart';
  }
}
