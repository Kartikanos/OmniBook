// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../models/inventory_item.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/shimmer_loader.dart';

import 'add_item_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      dbService.fetchAllData(isGuest: authService.isGuestMode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditItemDialog(BuildContext context, {InventoryItem? existingItem}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => AddItemScreen(existingItem: existingItem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final authService = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = dbService.searchInventory(_searchController.text);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dbService.fetchAllData(isGuest: authService.isGuestMode),
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 18, bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Add Item CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Utensils Inventory',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stock levels, Unit types & GST %',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => _showAddEditItemDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search stock items...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Stock Grid / List
                Expanded(
                  child: dbService.isLoading && items.isEmpty
                      ? const ShimmerListLoader(itemCount: 6)
                      : items.isEmpty
                          ? ListView(
                          children: [
                            const SizedBox(height: 60),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: isDark ? Colors.white30 : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No inventory items available.',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppConstants.textMutedDark
                                          : AppConstants.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (ctx, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isLowStock = item.stockQuantity <= 5;

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: isDark
                                    ? const BorderSide(color: Color(0xFF334155), width: 0.8)
                                    : BorderSide.none,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppConstants.primaryColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item.category ?? 'Utensils',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppConstants.primaryAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Details Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${AppConstants.formatCurrency(item.unitPrice)} / ${item.unit}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppConstants.primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'GST: ${item.gstRate.toStringAsFixed(0)}% ${item.weightKg != null ? "• Wt: ${item.weightKg}kg" : ""}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? AppConstants.textMutedDark
                                                    : AppConstants.textMutedLight,
                                              ),
                                            ),
                                          ],
                                        ),

                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: (isLowStock ? AppConstants.accentColor : AppConstants.cashInColor).withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isLowStock ? AppConstants.accentColor : AppConstants.cashInColor,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                'Qty: ${item.stockQuantity}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isLowStock ? AppConstants.accentColor : AppConstants.cashInColor,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 18),
                                              onPressed: () => _showAddEditItemDialog(context, existingItem: item),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppConstants.accentColor),
                                              onPressed: () async {
                                                final bool? confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Delete Item?'),
                                                    content: Text('Are you sure you want to delete "${item.name}" from inventory?'),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppConstants.accentColor,
                                                          foregroundColor: Colors.white,
                                                        ),
                                                        onPressed: () => Navigator.of(ctx).pop(true),
                                                        child: const Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true && context.mounted) {
                                                  final dbService = Provider.of<DatabaseService>(context, listen: false);
                                                  final authService = Provider.of<AuthService>(context, listen: false);
                                                  await dbService.deleteInventoryItem(item.id, isGuest: authService.isGuestMode);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('${item.name} deleted from inventory.'),
                                                        backgroundColor: AppConstants.accentColor,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fade().slideY(begin: 0.1, end: 0, delay: (index * 40).ms);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
