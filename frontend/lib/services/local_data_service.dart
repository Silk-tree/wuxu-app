import 'package:shared_preferences/shared_preferences.dart';

import '../models/item.dart';
import '../models/category.dart';
import 'db_helper.dart';

class LocalDataService {
  static const String _keyIsPremium = 'is_premium';
  static const int _freeItemLimit = 20;

  SharedPreferences? _prefs;

  LocalDataService();

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String _calculateStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final daysUntilExpiry = expiry.difference(today).inDays;

    if (daysUntilExpiry < 0) {
      return 'expired';
    } else if (daysUntilExpiry <= 3) {
      return 'warning';
    } else {
      return 'safe';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _isPremium() async {
    await _ensurePrefs();
    return _prefs!.getBool(_keyIsPremium) ?? false;
  }

  Future<void> _setPremium(bool value) async {
    await _ensurePrefs();
    await _prefs!.setBool(_keyIsPremium, value);
  }

  Future<int> _getItemCount() async {
    final db = await DbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM items');
    return result.first['count'] as int;
  }

  Future<List<Category>> getCategories() async {
    final db = await DbHelper.database;
    final maps = await db.query('categories', orderBy: 'sort_order ASC');
    return maps.map((m) => Category(
      id: m['id'] as String,
      name: m['name'] as String,
      icon: m['icon'] as String,
      sortOrder: m['sort_order'] as int,
    )).toList();
  }

  Future<List<Item>> getItems({
    String? status,
    String? categoryId,
    String sort = 'expiry_asc',
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await DbHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (status != null && status.isNotEmpty && status != 'all') {
      whereClause = 'status = ?';
      whereArgs.add(status);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'category_id = ?';
      whereArgs.add(categoryId);
    }

    String orderBy;
    switch (sort) {
      case 'expiry_desc':
        orderBy = 'expiry_date DESC';
        break;
      case 'name_asc':
        orderBy = 'name ASC';
        break;
      case 'name_desc':
        orderBy = 'name DESC';
        break;
      case 'created_desc':
        orderBy = 'created_at DESC';
        break;
      case 'expiry_asc':
      default:
        orderBy = 'expiry_date ASC';
    }

    final maps = await db.query(
      'items',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    // Get categories for mapping
    final categories = await getCategories();
    final categoryMap = {for (var c in categories) c.id: c};

    return maps.map((m) {
      final expiryDate = DateTime.parse(m['expiry_date'] as String);
      final item = Item(
        id: m['id'] as String,
        name: m['name'] as String,
        categoryId: m['category_id'] as String,
        quantity: m['quantity'] as int,
        unit: m['unit'] as String,
        expiryDate: expiryDate,
        storageLocation: m['storage_location'] as String,
        status: ItemStatusExtension.fromString(m['status'] as String),
        notes: m['notes'] as String,
        deviceId: m['device_id'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        category: categoryMap[m['category_id']],
      );
      // Recalculate status based on current date
      final calculatedStatus = _calculateStatus(expiryDate);
      return item.copyWith(status: ItemStatusExtension.fromString(calculatedStatus));
    }).toList();
  }

  Future<Item> getItemById(String id) async {
    final db = await DbHelper.database;
    final maps = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      throw Exception('物品不存在');
    }

    final m = maps.first;
    final expiryDate = DateTime.parse(m['expiry_date'] as String);
    final categories = await getCategories();
    final categoryMap = {for (var c in categories) c.id: c};

    return Item(
      id: m['id'] as String,
      name: m['name'] as String,
      categoryId: m['category_id'] as String,
      quantity: m['quantity'] as int,
      unit: m['unit'] as String,
      expiryDate: expiryDate,
      storageLocation: m['storage_location'] as String,
      status: ItemStatusExtension.fromString(m['status'] as String),
      notes: m['notes'] as String,
      deviceId: m['device_id'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
      category: categoryMap[m['category_id']],
    );
  }

  Future<Item> createItem(Item item) async {
    final db = await DbHelper.database;

    // Check item limit for non-premium users
    final isPremium = await _isPremium();
    if (!isPremium) {
      final count = await _getItemCount();
      if (count >= _freeItemLimit) {
        throw Exception('免费用户最多添加 $_freeItemLimit 个物品，请升级为付费版本');
      }
    }

    final now = DateTime.now();
    final expiryDate = item.expiryDate;
    final status = _calculateStatus(expiryDate);

    final map = {
      'id': item.id,
      'name': item.name,
      'category_id': item.categoryId,
      'quantity': item.quantity,
      'unit': item.unit,
      'expiry_date': _formatDate(expiryDate),
      'storage_location': item.storageLocation,
      'status': status,
      'notes': item.notes,
      'device_id': item.deviceId,
      'created_at': _formatDate(now),
      'updated_at': _formatDate(now),
    };

    await db.insert('items', map);

    // Return the created item with calculated status
    return item.copyWith(
      status: ItemStatusExtension.fromString(status),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<Item> updateItem(String id, Map<String, dynamic> data) async {
    final db = await DbHelper.database;

    // Get existing item
    final existingMaps = await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (existingMaps.isEmpty) {
      throw Exception('物品不存在');
    }

    // Build update map
    final updateMap = <String, dynamic>{
      'updated_at': _formatDate(DateTime.now()),
    };

    if (data.containsKey('name')) updateMap['name'] = data['name'];
    if (data.containsKey('category_id')) updateMap['category_id'] = data['category_id'];
    if (data.containsKey('quantity')) updateMap['quantity'] = data['quantity'];
    if (data.containsKey('unit')) updateMap['unit'] = data['unit'];
    if (data.containsKey('expiry_date')) {
      final newExpiry = data['expiry_date'] as DateTime;
      updateMap['expiry_date'] = _formatDate(newExpiry);
      updateMap['status'] = _calculateStatus(newExpiry);
    }
    if (data.containsKey('storage_location')) updateMap['storage_location'] = data['storage_location'];
    if (data.containsKey('notes')) updateMap['notes'] = data['notes'];

    await db.update('items', updateMap, where: 'id = ?', whereArgs: [id]);

    // Return updated item
    return await getItemById(id);
  }

  Future<void> deleteItem(String id) async {
    final db = await DbHelper.database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await DbHelper.database;

    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM items');
    final total = totalResult.first['count'] as int;

    final expiredResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM items WHERE status = 'expired'",
    );
    final expired = expiredResult.first['count'] as int;

    final warningResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM items WHERE status = 'warning'",
    );
    final warning = warningResult.first['count'] as int;

    final safeResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM items WHERE status = 'safe'",
    );
    final safe = safeResult.first['count'] as int;

    return {
      'total': total,
      'expired': expired,
      'warning': warning,
      'safe': safe,
    };
  }

  Future<bool> purchase() async {
    // Locally mark as premium
    await _setPremium(true);
    return true;
  }
}
