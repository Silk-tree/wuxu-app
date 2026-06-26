import 'dart:convert';
import 'dart:io';
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

  String _handleError(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}
    switch (response.statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '请先登录';
      case 403:
        return '没有权限执行此操作';
      case 404:
        return '请求的资源不存在';
      case 500:
        return '服务器内部错误';
      default:
        return '请求失败（${response.statusCode}）';
    }
  }

  Future<T> _request<T>(Future<http.Response> Function() requestFn, T Function(dynamic data) parser) async {
    try {
      final response = await requestFn();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return parser(data['data']);
      }
      throw Exception(_handleError(response));
    } on SocketException {
      throw Exception('网络连接失败，请检查网络设置');
    } on FormatException {
      throw Exception('数据格式错误');
    } on HttpException {
      throw Exception('网络请求异常');
    } catch (e) {
      if (e.toString().startsWith('Exception:')) {
        rethrow;
      }
      throw Exception('网络请求失败：${e.toString()}');
    }
  }

  Future<List<Category>> getCategories() async {
    return _request(
      () => _client.get(
        Uri.parse(ApiConstants.categories),
        headers: _headers,
      ),
      (data) {
        final List<dynamic> list = data as List<dynamic>? ?? [];
        return list.map((e) => Category.fromJson(e)).toList();
      },
    );
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
    return _request(
      () => _client.get(uri, headers: _headers),
      (data) {
        final List<dynamic> list = data['items'] as List<dynamic>? ?? [];
        return list.map((e) => Item.fromJson(e)).toList();
      },
    );
  }

  Future<Item> getItemById(String id) async {
    return _request(
      () => _client.get(
        Uri.parse(ApiConstants.itemById(id)),
        headers: _headers,
      ),
      (data) => Item.fromJson(data),
    );
  }

  Future<Item> createItem(Item item) async {
    return _request(
      () => _client.post(
        Uri.parse(ApiConstants.items),
        headers: _headers,
        body: json.encode(item.toJson()),
      ),
      (data) => Item.fromJson(data),
    );
  }

  Future<Item> updateItem(String id, Map<String, dynamic> data) async {
    return _request(
      () => _client.put(
        Uri.parse(ApiConstants.itemById(id)),
        headers: _headers,
        body: json.encode(data),
      ),
      (data) => Item.fromJson(data),
    );
  }

  Future<void> deleteItem(String id) async {
    await _request(
      () => _client.delete(
        Uri.parse(ApiConstants.itemById(id)),
        headers: _headers,
      ),
      (data) => null,
    );
  }

  Future<Map<String, dynamic>> getStats() async {
    return _request(
      () => _client.get(
        Uri.parse(ApiConstants.stats),
        headers: _headers,
      ),
      (data) => Map<String, dynamic>.from(data),
    );
  }

  Future<bool> purchase() async {
    return _request(
      () => _client.post(
        Uri.parse(ApiConstants.purchase),
        headers: _headers,
        body: json.encode({'device_id': deviceId}),
      ),
      (data) => data['success'] ?? false,
    );
  }
}
