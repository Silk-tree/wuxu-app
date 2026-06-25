import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api.dart';
import '../models/item.dart';
import '../models/category.dart';

class ApiService {
  final http.Client _client;
  final String deviceId;

  ApiService({http.Client? client, required this.deviceId})
      : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Device-ID': deviceId,
      };

  Future<List<Category>> getCategories() async {
    final response = await _client.get(
      Uri.parse(ApiConstants.categories),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['data'] ?? [];
      return list.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('获取分类失败');
  }

  Future<List<Item>> getItems({
    String? status,
    String? categoryId,
    String sort = 'expiry_asc',
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (categoryId != null && categoryId.isNotEmpty) {
      params['category_id'] = categoryId;
    }

    final uri = Uri.parse(ApiConstants.items).replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['data']['items'] ?? [];
      return list.map((e) => Item.fromJson(e)).toList();
    }
    throw Exception('获取物品列表失败');
  }

  Future<Item> getItemById(String id) async {
    final response = await _client.get(
      Uri.parse(ApiConstants.itemById(id)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Item.fromJson(data['data']);
    }
    throw Exception('获取物品详情失败');
  }

  Future<Item> createItem(Item item) async {
    final response = await _client.post(
      Uri.parse(ApiConstants.items),
      headers: _headers,
      body: json.encode(item.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return Item.fromJson(data['data']);
    } else if (response.statusCode == 403) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? '免费用户物品数量已达上限');
    }
    throw Exception('创建物品失败');
  }

  Future<Item> updateItem(String id, Map<String, dynamic> data) async {
    final response = await _client.put(
      Uri.parse(ApiConstants.itemById(id)),
      headers: _headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return Item.fromJson(body['data']);
    }
    throw Exception('更新物品失败');
  }

  Future<void> deleteItem(String id) async {
    final response = await _client.delete(
      Uri.parse(ApiConstants.itemById(id)),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('删除物品失败');
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _client.get(
      Uri.parse(ApiConstants.stats),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['data']);
    }
    throw Exception('获取统计信息失败');
  }

  Future<bool> purchase() async {
    final response = await _client.post(
      Uri.parse(ApiConstants.purchase),
      headers: _headers,
      body: json.encode({'device_id': deviceId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['success'] ?? false;
    }
    throw Exception('购买失败');
  }
}
