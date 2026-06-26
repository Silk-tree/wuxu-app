import '../models/item.dart';
import '../models/category.dart';
import 'local_data_service.dart';

class ApiService {
  final LocalDataService _localDataService = LocalDataService();
  final String deviceId;

  ApiService({required this.deviceId});

  Future<List<Category>> getCategories() async {
    return await _localDataService.getCategories();
  }

  Future<List<Item>> getItems({
    String? status,
    String? categoryId,
    String sort = 'expiry_asc',
    int limit = 50,
    int offset = 0,
  }) async {
    return await _localDataService.getItems(
      status: status,
      categoryId: categoryId,
      sort: sort,
      limit: limit,
      offset: offset,
    );
  }

  Future<Item> getItemById(String id) async {
    return await _localDataService.getItemById(id);
  }

  Future<Item> createItem(Item item) async {
    return await _localDataService.createItem(item);
  }

  Future<Item> updateItem(String id, Map<String, dynamic> data) async {
    return await _localDataService.updateItem(id, data);
  }

  Future<void> deleteItem(String id) async {
    await _localDataService.deleteItem(id);
  }

  Future<Map<String, dynamic>> getStats() async {
    return await _localDataService.getStats();
  }

  Future<bool> purchase() async {
    return await _localDataService.purchase();
  }
}
