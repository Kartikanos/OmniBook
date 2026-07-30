// ignore_for_file: avoid_print, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/supabase_config.dart';
import '../models/user_model.dart';
import '../models/inventory_item.dart';
import '../models/cash_entry.dart';
import '../models/party_model.dart';
import '../models/invoice_model.dart';
import '../models/staff_model.dart';

class DatabaseService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseConfig.client;

  UserModel? _currentUserModel;
  bool _isLoading = false;
  String? _errorMessage;

  List<CashEntry> _cashEntries = [];
  List<InventoryItem> _inventoryItems = [];
  List<Party> _parties = [];
  final List<Invoice> _invoices = [];
  List<StaffMember> _staffMembers = [];
  List<AttendanceRecord> _attendanceRecords = [];

  StreamSubscription? _cashStreamSub;
  StreamSubscription? _inventoryStreamSub;
  StreamSubscription? _partiesStreamSub;

  double _baseOpeningBalance = 35000.00;

  double get baseOpeningBalance => _baseOpeningBalance;

  /// Persists the new base opening balance to SharedPreferences and notifies listeners.
  Future<void> updateBaseOpeningBalance(double newBalance) async {
    _baseOpeningBalance = newBalance;
    notifyListeners();
    try {
      final userId = _client.auth.currentUser?.id;
      final key = userId != null ? 'base_opening_balance_$userId' : 'base_opening_balance_guest';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, newBalance);
      print('--- BASE OPENING BALANCE UPDATED: $newBalance ---');
    } catch (e) {
      print('Error persisting base opening balance: $e');
    }
  }

  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CashEntry> get cashEntries => List.unmodifiable(_cashEntries);
  List<InventoryItem> get inventoryItems => List.unmodifiable(_inventoryItems);
  List<Party> get parties => List.unmodifiable(_parties);
  List<Invoice> get invoices => List.unmodifiable(_invoices);
  List<StaffMember> get staffMembers => List.unmodifiable(_staffMembers);
  List<AttendanceRecord> get attendanceRecords => List.unmodifiable(_attendanceRecords);

  // Total Lifetime Cash In & Cash Out
  double get totalCashIn {
    return _cashEntries
        .where((e) => e.type == CashEntryType.cashIn)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalCashOut {
    return _cashEntries
        .where((e) => e.type == CashEntryType.cashOut)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Today's Cash In & Cash Out
  double get todaysCashIn {
    final now = DateTime.now();
    return _cashEntries
        .where((e) =>
            e.type == CashEntryType.cashIn &&
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get todaysCashOut {
    final now = DateTime.now();
    return _cashEntries
        .where((e) =>
            e.type == CashEntryType.cashOut &&
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Dynamic Opening Balance carried over from previous days
  double get todaysOpeningBalance {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final previousCashIn = _cashEntries
        .where((e) => e.type == CashEntryType.cashIn && e.date.isBefore(todayStart))
        .fold(0.0, (sum, item) => sum + item.amount);

    final previousCashOut = _cashEntries
        .where((e) => e.type == CashEntryType.cashOut && e.date.isBefore(todayStart))
        .fold(0.0, (sum, item) => sum + item.amount);

    return _baseOpeningBalance + previousCashIn - previousCashOut;
  }

  // Net Closing Balance
  double get closingBalance {
    return todaysOpeningBalance + todaysCashIn - todaysCashOut;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _cancelSubscriptions() {
    _cashStreamSub?.cancel();
    _inventoryStreamSub?.cancel();
    _partiesStreamSub?.cancel();
    _cashStreamSub = null;
    _inventoryStreamSub = null;
    _partiesStreamSub = null;
  }

  // Offline SharedPreferences Caching
  Future<void> _loadFromLocalCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cashStr = prefs.getString('cached_cash_entries_$userId');
      if (cashStr != null && cashStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cashStr);
        _cashEntries = list.map((e) => CashEntry.fromJson(e as Map<String, dynamic>)).toList();
      }

      final invStr = prefs.getString('cached_inventory_items_$userId');
      if (invStr != null && invStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(invStr);
        _inventoryItems = list.map((e) => InventoryItem.fromJson(e as Map<String, dynamic>)).toList();
      }

      final partyStr = prefs.getString('cached_parties_$userId');
      if (partyStr != null && partyStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(partyStr);
        _parties = list.map((e) => Party.fromJson(e as Map<String, dynamic>)).toList();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading local SharedPreferences cache: $e');
    }
  }

  Future<void> _saveToLocalCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cashJson = jsonEncode(_cashEntries.map((e) => e.toJson()).toList());
      await prefs.setString('cached_cash_entries_$userId', cashJson);

      final invJson = jsonEncode(_inventoryItems.map((e) => e.toJson()).toList());
      await prefs.setString('cached_inventory_items_$userId', invJson);

      final partyJson = jsonEncode(_parties.map((e) => e.toJson()).toList());
      await prefs.setString('cached_parties_$userId', partyJson);
    } catch (e) {
      if (kDebugMode) print('Error saving local SharedPreferences cache: $e');
    }
  }

  // Clear in-memory UI state and cancel subscriptions on logout (Cloud rows remain 100% untouched)
  Future<void> clearUserData() async {
    _cancelSubscriptions();

    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_cash_entries_$userId');
        await prefs.remove('cached_inventory_items_$userId');
        await prefs.remove('cached_parties_$userId');
      } catch (e) {
        if (kDebugMode) print('Error clearing SharedPreferences cache: $e');
      }
    }

    _cashEntries = [];
    _inventoryItems = [];
    _parties = [];
    _invoices.clear();
    _staffMembers = [];
    _attendanceRecords = [];
    _currentUserModel = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Load all initial data for Dashboard, CashBook, Inventory, Parties, Staff with Real-Time Streams
  Future<void> fetchAllData({bool isGuest = false}) async {
    _setLoading(true);
    _errorMessage = null;

    if (isGuest) {
      _cancelSubscriptions();
      _loadSampleGuestData();
      _setLoading(false);
      return;
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _cancelSubscriptions();
      _cashEntries = [];
      _inventoryItems = [];
      _parties = [];
      _staffMembers = [];
      _attendanceRecords = [];
      _setLoading(false);
      return;
    }

    // Step 1: Load from local SharedPreferences cache FIRST so UI renders immediately
    await _loadFromLocalCache(userId);

    // Step 1b: Restore persisted base opening balance
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble('base_opening_balance_$userId');
      if (saved != null) _baseOpeningBalance = saved;
    } catch (_) {}

    // Step 2: Fetch each table in distinct, isolated try-catch blocks so one table error never breaks others!

    // A) Fetch CashBook Entries (schema truth: id, user_id, title, amount, type, category, party_id, created_at)
    try {
      final response = await _client
          .from(AppConstants.cashEntriesTable)
          .select('id, user_id, title, amount, type, category, party_id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _cashEntries = (response as List)
          .map((e) => CashEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      print('SUCCESSFULLY LOADED ${_cashEntries.length} CASHBOOK ROWS');
    } catch (e) {
      print('CASHBOOK FETCH ERROR: $e');
    }

    // B) Fetch Inventory Items
    try {
      final response = await _client
          .from(AppConstants.inventoryTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _inventoryItems = (response as List)
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      print('SUCCESSFULLY LOADED ${_inventoryItems.length} INVENTORY ROWS');
    } catch (e) {
      print('INVENTORY FETCH ERROR: $e');
    }

    // C) Fetch Ledgers / Parties (schema truth: id, user_id, name, phone, party_type, opening_balance, current_balance, created_at)
    try {
      final response = await _client
          .from(AppConstants.ledgersTable)
          .select('id, user_id, name, phone, party_type, opening_balance, current_balance, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final fetchedParties = (response as List)
          .map((e) => Party.fromJson(e as Map<String, dynamic>))
          .toList();

      final Map<String, Party> partyMap = {};
      for (final p in _parties) {
        partyMap[p.id] = p;
      }
      for (final p in fetchedParties) {
        partyMap[p.id] = p;
      }
      _parties = partyMap.values.toList();
      _parties.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('SUCCESSFULLY LOADED ${_parties.length} LEDGER ROWS (${fetchedParties.length} remote)');
    } catch (e) {
      print('LEDGER FETCH ERROR: $e');
    }

    // D) Fetch Worker Attendance
    try {
      final response = await _client
          .from('worker_attendance')
          .select()
          .eq('user_id', userId);

      if ((response as List).isNotEmpty) {
        _attendanceRecords = (response as List).map((e) {
          final rawStatus = (e['status']?.toString() ?? '').toUpperCase();
          AttendanceStatus st = AttendanceStatus.absent;
          if (rawStatus.contains('PRESENT')) st = AttendanceStatus.present;
          if (rawStatus.contains('HALF')) st = AttendanceStatus.halfDay;

          final dStr = e['date']?.toString() ?? e['created_at']?.toString() ?? '';
          final d = dStr.isNotEmpty ? (DateTime.tryParse(dStr) ?? DateTime.now()) : DateTime.now();

          return AttendanceRecord(
            id: e['id']?.toString() ?? const Uuid().v4(),
            staffId: e['staff_id']?.toString() ?? '',
            date: d,
            status: st,
          );
        }).toList();
        print('SUCCESSFULLY LOADED ${_attendanceRecords.length} ATTENDANCE ROWS');
      }
    } catch (e) {
      print('WORKER ATTENDANCE FETCH NOTICE: $e');
    }

    // E) Fetch Workers from Supabase (schema truth: id, user_id, name, phone, daily_salary, is_active, created_at)
    try {
      final workersResponse = await _client
          .from('workers')
          .select('id, user_id, name, phone, daily_salary, is_active, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _staffMembers = (workersResponse as List)
          .map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
          .toList();
      print('SUCCESSFULLY LOADED ${_staffMembers.length} WORKER ROWS');
    } catch (e) {
      print('WORKERS FETCH NOTICE: $e');
    }

    // Step 3: Save fresh state to local SharedPreferences cache & process any pending offline items
    await _saveToLocalCache(userId);
    await syncOfflineQueue();

    // Step 4: Setup Supabase Real-Time Streams for Live Auto-Syncing
    _setupRealtimeStreams(userId);

    _setLoading(false);
  }

  double calculatePartyNetBalance(String partyId) {
    final partyIndex = _parties.indexWhere((p) => p.id == partyId);
    if (partyIndex == -1) return 0.0;
    final party = _parties[partyIndex];

    final partyTxns = _cashEntries.where((e) => e.partyId == partyId).toList();
    double totalCashIn = 0.0;
    double totalCashOut = 0.0;
    for (final txn in partyTxns) {
      if (txn.type == CashEntryType.cashIn) {
        totalCashIn += txn.amount;
      } else {
        totalCashOut += txn.amount;
      }
    }

    return party.openingBalance + totalCashIn - totalCashOut;
  }

  // Setup Supabase Real-Time Streams for live database updates with error isolation
  void _setupRealtimeStreams(String userId) {
    _cancelSubscriptions();

    // 1. Cashbook Stream
    try {
      _cashStreamSub = _client
          .from(AppConstants.cashEntriesTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((data) {
            _cashEntries = data
                .map((item) => CashEntry.fromJson(item))
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            _saveToLocalCache(userId);
            notifyListeners();
          }, onError: (e) {
            print('SUPABASE REALTIME CASH STREAM ERROR: $e');
          });
    } catch (e) {
      print('CASH REALTIME STREAM INIT ERROR: $e');
    }

    // 2. Inventory Stream
    try {
      _inventoryStreamSub = _client
          .from(AppConstants.inventoryTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((data) {
            _inventoryItems = data
                .map((item) => InventoryItem.fromJson(item))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _saveToLocalCache(userId);
            notifyListeners();
          }, onError: (e) {
            print('SUPABASE REALTIME INVENTORY STREAM ERROR: $e');
          });
    } catch (e) {
      print('INVENTORY REALTIME STREAM INIT ERROR: $e');
    }

    // 3. Ledgers / Parties Stream
    try {
      _partiesStreamSub = _client
          .from(AppConstants.ledgersTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((data) {
            _parties = data
                .map((item) => Party.fromJson(item))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _saveToLocalCache(userId);
            notifyListeners();
          }, onError: (e) {
            print('SUPABASE REALTIME LEDGER STREAM ERROR: $e');
          });
    } catch (e) {
      print('LEDGER REALTIME STREAM INIT ERROR: $e');
    }
  }

  void _deduplicateInventory() {
    final Map<String, InventoryItem> unique = {};
    for (var item in _inventoryItems) {
      final key = item.name.toLowerCase().trim();
      if (!unique.containsKey(key)) {
        unique[key] = item;
      }
    }
    _inventoryItems = unique.values.toList();
  }

  // Add Cash Entry (Cash In / Cash Out) with explicit debug logging
  Future<bool> addCashEntry(CashEntry entry, {bool isGuest = false}) async {
    try {
      String formattedTitle = entry.title;
      if (entry.category == 'Party Payment' || formattedTitle.trim().isEmpty) {
        if (entry.partyId != null && entry.partyId!.isNotEmpty) {
          final pIndex = _parties.indexWhere((p) => p.id == entry.partyId);
          if (pIndex != -1) {
            final pName = _parties[pIndex].name;
            formattedTitle = entry.type == CashEntryType.cashIn
                ? 'Received from $pName'
                : 'Paid to $pName';
          }
        }
      }

      final finalEntry = CashEntry(
        id: entry.id,
        type: entry.type,
        category: entry.category,
        title: formattedTitle,
        partyId: entry.partyId,
        amount: entry.amount,
        date: entry.date,
      );

      // Optimistic local insertion
      _cashEntries.insert(0, finalEntry);

      // 2. Link with Party Ledger & Dynamic Role Assignment
      if (finalEntry.partyId != null && finalEntry.partyId!.isNotEmpty) {
        final pIndex = _parties.indexWhere((p) => p.id == finalEntry.partyId);
        if (pIndex != -1) {
          final party = _parties[pIndex];
          double newBal = party.currentBalance;
          if (finalEntry.type == CashEntryType.cashIn) {
            newBal += finalEntry.amount;
          } else {
            newBal -= finalEntry.amount;
          }

          // Compute dynamic role from history
          final partyTxns = _cashEntries.where((e) => e.partyId == party.id).toList();
          final hasCashIn = partyTxns.any((e) => e.type == CashEntryType.cashIn);
          final hasCashOut = partyTxns.any((e) => e.type == CashEntryType.cashOut);

          PartyType updatedType = party.type;
          if (hasCashIn && hasCashOut) {
            updatedType = PartyType.both;
          } else if (hasCashOut) {
            updatedType = PartyType.supplier;
          } else if (hasCashIn) {
            updatedType = PartyType.customer;
          }

          final updatedParty = party.copyWith(
            currentBalance: newBal,
            type: updatedType,
          );
          _parties[pIndex] = updatedParty;

          // Push updated party to Supabase
          if (!isGuest) {
            final userId = _client.auth.currentUser?.id;
            if (userId != null) {
              try {
                await _client
                    .from(AppConstants.ledgersTable)
                    .update(updatedParty.toSupabaseUpdate(userId))
                    .eq('id', party.id);
                print('--- DYNAMICALLY UPDATED PARTY ROLE (${updatedParty.typeLabel}) & BALANCE ($newBal) ---');
              } catch (e) {
                print('Error updating party in Supabase: $e');
              }
            }
          }
        }
      }

      // If item purchase/sale, adjust inventory stock
      if (finalEntry.itemId != null && finalEntry.category.contains('Item')) {
        final index = _inventoryItems.indexWhere((i) => i.id == finalEntry.itemId);
        if (index != -1) {
          final item = _inventoryItems[index];
          int updatedStock = item.stockQuantity;
          if (finalEntry.type == CashEntryType.cashIn) {
            updatedStock = (updatedStock - finalEntry.quantity).clamp(0, 999999);
          } else {
            updatedStock += finalEntry.quantity;
          }
          _inventoryItems[index] = item.copyWith(stockQuantity: updatedStock);
        }
      }

      // Optimistic UI Notification
      notifyListeners();

      // Save to Supabase Cloud asynchronously
      if (!isGuest) {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          try {
            final jsonMap = finalEntry.toSupabaseInsert(userId);
            print('--- ATTEMPTING SUPABASE INSERT ---');
            print('JSON Payload: $jsonMap');

            final response = await _client
                .from(AppConstants.cashEntriesTable)
                .insert(jsonMap)
                .select();
            print('--- SUCCESS! INSERTED ROW IN ${AppConstants.cashEntriesTable}: $response ---');
          } catch (e) {
            print('--- SUPABASE NETWORK/OFFLINE NOTICE: $e ---');
            await _addToOfflineQueue(userId, 'cash', finalEntry.toJson());
          }
          await _saveToLocalCache(userId);
        }
      }

      return true;
    } catch (e) {
      print('Add cash entry failed: $e');
      _errorMessage = 'Could not save transaction.';
      return false;
    }
  }

  /// Update an existing cash entry (amount, title, category, date, notes)
  Future<bool> updateCashEntry(CashEntry updated, {bool isGuest = false}) async {
    try {
      final idx = _cashEntries.indexWhere((e) => e.id == updated.id);
      if (idx == -1) return false;

      _cashEntries[idx] = updated;
      notifyListeners();

      if (!isGuest) {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          try {
            await _client
                .from(AppConstants.cashEntriesTable)
                .update(updated.toSupabaseUpdate(userId))
                .eq('id', updated.id)
                .eq('user_id', userId);
            print('--- SUCCESS! UPDATED CASH ENTRY: ${updated.id} ---');
          } catch (e) {
            print('--- SUPABASE CASH ENTRY UPDATE NOTICE: $e ---');
          }
          await _saveToLocalCache(userId);
        }
      }

      return true;
    } catch (e) {
      print('Update cash entry failed: $e');
      _errorMessage = 'Could not update transaction.';
      return false;
    }
  }
  /// Permanently delete a cash entry from local state and Supabase
  Future<bool> deleteCashEntry(String entryId, {bool isGuest = false}) async {
    try {
      _cashEntries.removeWhere((e) => e.id == entryId);
      notifyListeners();

      if (!isGuest) {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          try {
            await _client
                .from(AppConstants.cashEntriesTable)
                .delete()
                .eq('id', entryId)
                .eq('user_id', userId);
            print('--- SUCCESS! DELETED CASH ENTRY: $entryId ---');
          } catch (e) {
            print('--- SUPABASE CASH ENTRY DELETE NOTICE: $e ---');
          }
          await _saveToLocalCache(userId);
        }
      }

      return true;
    } catch (e) {
      print('Delete cash entry failed: $e');
      _errorMessage = 'Could not delete transaction.';
      return false;
    }
  }

  // Add Item to local offline pending queue
  Future<void> _addToOfflineQueue(String userId, String type, Map<String, dynamic> json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_pending_${type}_$userId';
      final existingStr = prefs.getString(key);
      List<dynamic> list = [];
      if (existingStr != null && existingStr.isNotEmpty) {
        list = jsonDecode(existingStr);
      }
      list.add(json);
      await prefs.setString(key, jsonEncode(list));
      print('Item added to offline queue ($key). Total pending: ${list.length}');
    } catch (e) {
      print('Error adding to offline queue: $e');
    }
  }

  // Process offline sync queue when network connectivity is available
  Future<void> syncOfflineQueue() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cashKey = 'cached_pending_cash_$userId';
      final cashStr = prefs.getString(cashKey);
      if (cashStr != null && cashStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cashStr);
        final pendingEntries = list.map((e) => CashEntry.fromJson(e as Map<String, dynamic>)).toList();
        final List<CashEntry> remaining = [];

        for (var entry in pendingEntries) {
          try {
            await _client.from(AppConstants.cashEntriesTable).insert(entry.toSupabaseInsert(userId));
            print('OFFLINE QUEUE SYNCED CashEntry: ${entry.id}');
          } catch (e) {
            remaining.add(entry);
          }
        }

        if (remaining.isEmpty) {
          await prefs.remove(cashKey);
        } else {
          await prefs.setString(cashKey, jsonEncode(remaining.map((e) => e.toJson()).toList()));
        }
      }
    } catch (e) {
      if (kDebugMode) print('Offline queue sync error: $e');
    }
  }

  // Add or Edit Utensil Inventory Item with UPDATE query on edit
  Future<InventoryItem?> addInventoryItem(InventoryItem item, {bool isGuest = false}) async {
    try {
      final existingIndex = _inventoryItems.indexWhere((i) => i.id == item.id);
      final isEditing = existingIndex != -1;

      if (isEditing) {
        _inventoryItems[existingIndex] = item;
      } else {
        _inventoryItems.insert(0, item);
      }
      _deduplicateInventory();

      // Optimistic UI Notification immediately
      notifyListeners();

      if (!isGuest) {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          try {
            final jsonMap = item.toSupabaseInsert(userId);
            if (isEditing) {
              print('--- ATTEMPTING SUPABASE INVENTORY UPDATE (id: ${item.id}) ---');
              await _client
                  .from(AppConstants.inventoryTable)
                  .update(jsonMap)
                  .eq('id', item.id);
              print('--- SUCCESS! UPDATED INVENTORY ITEM: ${item.id} ---');
            } else {
              print('--- ATTEMPTING SUPABASE INVENTORY INSERT ---');
              final response = await _client
                  .from(AppConstants.inventoryTable)
                  .insert(jsonMap)
                  .select();
              print('--- SUCCESS! INSERTED INVENTORY ROW: $response ---');
            }
            await fetchInventoryItems(isGuest: isGuest);
          } catch (e) {
            print('--- SUPABASE INVENTORY OFFLINE QUEUED: $e ---');
            await _addToOfflineQueue(userId, 'inventory', item.toJson());
          }
          await _saveToLocalCache(userId);
        }
      }

      return item;
    } catch (e) {
      print('Add inventory item failed: $e');
      _errorMessage = 'Failed to add item to inventory.';
      return null;
    }
  }

  Future<void> fetchInventoryItems({bool isGuest = false}) async {
    if (isGuest) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await _client
          .from(AppConstants.inventoryTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _inventoryItems = (response as List)
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _deduplicateInventory();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('FETCH INVENTORY ERROR: $e');
    }
  }

  // Delete Inventory Item live from Supabase & local state
  Future<bool> deleteInventoryItem(String itemId, {bool isGuest = false}) async {
    try {
      _inventoryItems.removeWhere((i) => i.id == itemId);
      notifyListeners();

      if (!isGuest) {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          try {
            await _client
                .from(AppConstants.inventoryTable)
                .delete()
                .eq('id', itemId);
            print('--- SUCCESS! DELETED INVENTORY ITEM: $itemId ---');
          } catch (e) {
            print('--- SUPABASE INVENTORY DELETE ERROR: $e ---');
          }
          await _saveToLocalCache(userId);
        }
      }
      return true;
    } catch (e) {
      print('Delete inventory item failed: $e');
      return false;
    }
  }

  // Search local inventory items for autocomplete
  List<InventoryItem> searchInventory(String query) {
    if (query.trim().isEmpty) return _inventoryItems;
    final lower = query.toLowerCase().trim();
    return _inventoryItems
        .where((item) => item.name.toLowerCase().contains(lower))
        .toList();
  }

  // Add / Edit Party with explicit debug logging
  Future<Party?> addParty(Party party, {bool isGuest = false}) async {
    try {
      Party savedParty = party;

      if (!isGuest) {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          try {
            final jsonMap = party.toSupabaseInsert(userId);
            print('--- ATTEMPTING SUPABASE LEDGER INSERT ---');
            print('Payload: $jsonMap');

            final response = await _client
                .from(AppConstants.ledgersTable)
                .insert(jsonMap)
                .select();
            print('--- SUCCESS! INSERTED LEDGER ROW: $response ---');
            if ((response as List).isNotEmpty) {
              savedParty = Party.fromJson(response.first);
            }
          } catch (e) {
            print('--- SUPABASE LEDGER OFFLINE QUEUED: $e ---');
            await _addToOfflineQueue(userId, 'ledgers', party.toJson());
          }
        }
      }

      final existingIndex = _parties.indexWhere((p) => p.id == party.id || p.id == savedParty.id);
      if (existingIndex != -1) {
        _parties[existingIndex] = savedParty;
      } else {
        _parties.insert(0, savedParty);
      }

      if (!isGuest && _client.auth.currentUser?.id != null) {
        await _saveToLocalCache(_client.auth.currentUser!.id);
      }

      notifyListeners();
      return savedParty;
    } catch (e) {
      print('Add party failed: $e');
      _errorMessage = 'Failed to add party.';
      return null;
    }
  }

  // Filter Parties (Suppliers / Customers / All)
  List<Party> searchParties(String query, {String? filterType}) {
    List<Party> filtered = _parties;
    if (filterType == 'Suppliers') {
      filtered = _parties.where((p) => p.type == PartyType.supplier || p.type == PartyType.both).toList();
    } else if (filterType == 'Customers') {
      filtered = _parties.where((p) => p.type == PartyType.customer || p.type == PartyType.both).toList();
    }

    if (query.trim().isEmpty) return filtered;
    final lower = query.toLowerCase().trim();
    return filtered.where((p) => p.name.toLowerCase().contains(lower) || p.phone.contains(lower)).toList();
  }

  // Get Cash Entries for a specific Party
  List<CashEntry> getPartyCashEntries(String partyId) {
    return _cashEntries.where((e) => e.partyId == partyId).toList();
  }

  // Create GST Invoice
  Future<bool> createInvoice(Invoice invoice, {bool isGuest = false}) async {
    try {
      _invoices.insert(0, invoice);

      // Create Cash Entry
      final cashEntry = CashEntry(
        id: const Uuid().v4(),
        type: CashEntryType.cashIn,
        category: 'Item Sale',
        partyId: invoice.partyId,
        title: 'GST Invoice #${invoice.invoiceNo} generated',
        amount: invoice.grandTotal,
        date: invoice.date,
      );

      await addCashEntry(cashEntry, isGuest: isGuest);

      // Deduct inventory stock for each line item
      for (var item in invoice.items) {
        final idx = _inventoryItems.indexWhere((i) => i.id == item.itemId);
        if (idx != -1) {
          final invItem = _inventoryItems[idx];
          final updatedStock = (invItem.stockQuantity - item.quantity).clamp(0, 999999);
          _inventoryItems[idx] = invItem.copyWith(stockQuantity: updatedStock);
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to generate invoice.';
      return false;
    }
  }

  // Staff & Attendance Methods
  Future<StaffMember?> addStaffMember(StaffMember staff, {bool isGuest = false}) async {
    try {
      final idx = _staffMembers.indexWhere((s) => s.id == staff.id);
      if (idx != -1) {
        _staffMembers[idx] = staff;
      } else {
        _staffMembers.insert(0, staff);
      }
      notifyListeners();

      if (!isGuest) {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          try {
            await _client.from('workers').upsert(staff.toSupabaseInsert(userId));
            print('--- SUCCESS! UPSERTED WORKER TO SUPABASE: ${staff.name} ---');
          } catch (e) {
            print('SUPABASE WORKER UPSERT NOTICE: $e');
          }
        }
      }

      return staff;
    } catch (e) {
      _errorMessage = 'Failed to add staff member.';
      return null;
    }
  }

  Future<bool> deleteStaffMember(String staffId, {bool isGuest = false}) async {
    try {
      _staffMembers.removeWhere((s) => s.id == staffId);
      _attendanceRecords.removeWhere((a) => a.staffId == staffId);
      notifyListeners();

      if (!isGuest) {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          try {
            await _client
                .from('workers')
                .delete()
                .eq('id', staffId)
                .eq('user_id', userId);
            print('--- SUCCESS! PERMANENTLY DELETED WORKER FROM SUPABASE: $staffId ---');
          } catch (e) {
            print('SUPABASE WORKER DELETE NOTICE: $e');
          }
        }
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete staff member.';
      return false;
    }
  }

  Future<void> markAttendance(String staffId, DateTime date, AttendanceStatus status, {bool isGuest = false}) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final existingIdx = _attendanceRecords.indexWhere(
      (a) => a.staffId == staffId && '${a.date.year}-${a.date.month.toString().padLeft(2, '0')}-${a.date.day.toString().padLeft(2, '0')}' == dateStr,
    );

    final record = AttendanceRecord(
      id: 'att_${staffId}_$dateStr',
      staffId: staffId,
      date: date,
      status: status,
    );

    if (existingIdx != -1) {
      _attendanceRecords[existingIdx] = record;
    } else {
      _attendanceRecords.insert(0, record);
    }
    notifyListeners();

    if (!isGuest) {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        try {
          final String statusStr = status == AttendanceStatus.present
              ? 'PRESENT'
              : (status == AttendanceStatus.halfDay ? 'HALF_DAY' : 'ABSENT');

          await _client.from('worker_attendance').upsert({
            'user_id': userId,
            'staff_id': staffId,
            'date': dateStr,
            'status': statusStr,
            'created_at': DateTime.now().toIso8601String(),
          });
          print('--- SUCCESS! SAVED WORKER ATTENDANCE TO SUPABASE: $staffId ($statusStr) ---');
        } catch (e) {
          print('SUPABASE WORKER ATTENDANCE NOTICE: $e');
        }
        await _saveToLocalCache(userId);
      }
    }
  }

  double calculateMonthlyWage(String staffId, int year, int month) {
    final staff = _staffMembers.firstWhere((s) => s.id == staffId, orElse: () => StaffMember(id: '', name: '', phone: '', designation: '', dailyWage: 0));
    if (staff.id.isEmpty) return 0.0;

    final records = _attendanceRecords.where(
      (a) => a.staffId == staffId && a.date.year == year && a.date.month == month,
    );

    double totalDays = 0.0;
    for (var r in records) {
      if (r.status == AttendanceStatus.present) totalDays += 1.0;
      if (r.status == AttendanceStatus.halfDay) totalDays += 0.5;
    }

    return totalDays * staff.dailyWage;
  }

  // Fetch user profile
  Future<UserModel?> getUserProfile(String userId, {String? email}) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final data = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        _currentUserModel = UserModel.fromJson(data);
      } else {
        final newModel = UserModel(
          id: userId,
          email: email ?? '',
          fullName: '',
          createdAt: DateTime.now(),
        );
        _currentUserModel = newModel;
      }
      return _currentUserModel;
    } catch (e) {
      _currentUserModel = UserModel(id: userId, email: email ?? 'user@omnibook.app');
      return _currentUserModel;
    } finally {
      _setLoading(false);
    }
  }

  // Save profile updates to Supabase database
  Future<bool> upsertUserProfile(UserModel profile) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      try {
        await _client
            .from(AppConstants.profilesTable)
            .upsert(profile.toJson());
        print('Successfully upserted profile to Supabase for user: ${profile.id}');
      } catch (e) {
        print('SUPABASE PROFILE UPSERT ERROR: $e');
      }

      _currentUserModel = profile;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save profile updates.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sample Utensils & Hardware Dataset
  void _loadSampleGuestData() {
    _inventoryItems = _defaultUtensilsInventory();
    _parties = _defaultSampleParties();
    _cashEntries = _defaultSampleCashEntries();
    _staffMembers = _defaultSampleStaff();
    _attendanceRecords = _defaultSampleAttendance();
  }

  List<InventoryItem> _defaultUtensilsInventory() {
    return [
      InventoryItem(
        id: const Uuid().v4(),
        name: 'Stainless Steel Lota (Embossed)',
        salePrice: 180.00,
        stockQuantity: 45,
        unit: 'Pieces',
        weightKg: 0.35,
        gstRate: 5.0,
        category: 'Pooja Utensils',
      ),
      InventoryItem(
        id: const Uuid().v4(),
        name: 'Brass Jug Premium 1.5L',
        salePrice: 650.00,
        stockQuantity: 22,
        unit: 'Pieces',
        weightKg: 1.20,
        gstRate: 12.0,
        category: 'Brassware',
      ),
      InventoryItem(
        id: const Uuid().v4(),
        name: 'Heavy Aluminium Patila 10L',
        salePrice: 320.00,
        stockQuantity: 60,
        unit: 'Kg',
        weightKg: 2.50,
        gstRate: 5.0,
        category: 'Cookware',
      ),
      InventoryItem(
        id: const Uuid().v4(),
        name: 'Stainless Steel Thali Set (6-pc)',
        salePrice: 450.00,
        stockQuantity: 30,
        unit: 'Set',
        weightKg: 1.10,
        gstRate: 5.0,
        category: 'Dinnerware',
      ),
      InventoryItem(
        id: const Uuid().v4(),
        name: 'Pure Copper Bottle 1000ml',
        salePrice: 850.00,
        stockQuantity: 18,
        unit: 'Pieces',
        weightKg: 0.42,
        gstRate: 12.0,
        category: 'Copperware',
      ),
    ];
  }

  List<Party> _defaultSampleParties() {
    return [
      Party(
        id: const Uuid().v4(),
        name: 'Ramesh Hardware & Steel Store',
        phone: '9876543210',
        type: PartyType.customer,
        openingBalance: 14500.00,
        currentBalance: 14500.00,
      ),
      Party(
        id: const Uuid().v4(),
        name: 'Gupta Utensil Udyog',
        phone: '9812345678',
        type: PartyType.supplier,
        openingBalance: -28000.00,
        currentBalance: -28000.00,
      ),
      Party(
        id: const Uuid().v4(),
        name: 'Janta Metal Works',
        phone: '9711223344',
        type: PartyType.both,
        openingBalance: 5200.00,
        currentBalance: 5200.00,
      ),
    ];
  }

  List<CashEntry> _defaultSampleCashEntries() {
    final now = DateTime.now();
    return [
      CashEntry(
        id: const Uuid().v4(),
        type: CashEntryType.cashIn,
        category: 'Item Sale',
        title: 'Brass Jug Premium 1.5L',
        amount: 3250.00,
        date: now,
      ),
      CashEntry(
        id: const Uuid().v4(),
        type: CashEntryType.cashOut,
        category: 'Party Payment',
        title: 'Paid to Gupta Utensil Udyog',
        amount: 15000.00,
        date: now.subtract(const Duration(hours: 3)),
      ),
      CashEntry(
        id: const Uuid().v4(),
        type: CashEntryType.cashIn,
        category: 'Item Sale',
        title: 'Stainless Steel Thali Set (6-pc)',
        amount: 4500.00,
        date: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  List<StaffMember> _defaultSampleStaff() {
    return [
      StaffMember(
        id: 'stf_1',
        name: 'Ram Singh',
        phone: '9811122233',
        designation: 'Store Helper',
        dailyWage: 500.00,
      ),
      StaffMember(
        id: 'stf_2',
        name: 'Mohan Kumar',
        phone: '9822233344',
        designation: 'Brass & Copper Polisher',
        dailyWage: 650.00,
      ),
      StaffMember(
        id: 'stf_3',
        name: 'Suresh Sharma',
        phone: '9833344455',
        designation: 'Sales & Inventory Manager',
        dailyWage: 800.00,
      ),
    ];
  }

  List<AttendanceRecord> _defaultSampleAttendance() {
    final now = DateTime.now();
    return [
      AttendanceRecord(
        id: 'att_1',
        staffId: 'stf_1',
        date: now,
        status: AttendanceStatus.present,
      ),
      AttendanceRecord(
        id: 'att_2',
        staffId: 'stf_2',
        date: now,
        status: AttendanceStatus.halfDay,
      ),
      AttendanceRecord(
        id: 'att_3',
        staffId: 'stf_3',
        date: now,
        status: AttendanceStatus.present,
      ),
    ];
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
