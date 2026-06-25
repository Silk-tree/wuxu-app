import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../models/category.dart' as cat;
import '../services/api_service.dart';

class ItemProvider with ChangeNotifier {
  final ApiService _apiService;

  ItemProvider({required ApiService apiService}) : _apiService = apiService;

  List<Item> _items = [];
  List<cat.Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _currentStatus = 'all';
  String _currentCategory = '';
  String _currentSort = 'expiry_asc';

  List<Item> get items => _items;
  List<cat.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentStatus => _currentStatus;
  String get currentCategory => _currentCategory;
  String get currentSort => _currentSort;

  List<Item> get expiredItems =>
      _items.where((i) => i.status == ItemStatus.expired).toList();

  List<Item> get warningItems =>
      _items.where((i) => i.status == ItemStatus.warning).toList();

  List<Item> get safeItems =>
      _items.where((i) => i.status == ItemStatus.safe).toList();

  int get totalCount => _items.length;
  int get expiredCount => expiredItems.length;
  int get warningCount => warningItems.length;
  int get safeCount => safeItems.length;

  Future<void> loadCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadItems({
    String? status,
    String? categoryId,
    String? sort,
    bool reload = false,
  }) async {
    if (status != null) _currentStatus = status;
    if (categoryId != null) _currentCategory = categoryId;
    if (sort != null) _currentSort = sort;

    if (!reload && _items.isNotEmpty && !_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _apiService.getItems(
        status: _currentStatus == 'all' ? null : _currentStatus,
        categoryId: _currentCategory.isEmpty ? null : _currentCategory,
        sort: _currentSort,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Item?> createItem(Item item) async {
    try {
      final created = await _apiService.createItem(item);
      _items.add(created);
      _items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _apiService.updateItem(id, data);
      final index = _items.indexWhere((i) => i.id == id);
      if (index != -1) {
        _items[index] = updated;
        _items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _apiService.deleteItem(id);
      _items.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Item? getItemById(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
