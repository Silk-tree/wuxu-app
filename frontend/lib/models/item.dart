import 'category.dart';

enum ItemStatus { safe, warning, expired }

extension ItemStatusExtension on ItemStatus {
  String get value {
    switch (this) {
      case ItemStatus.safe:
        return 'safe';
      case ItemStatus.warning:
        return 'warning';
      case ItemStatus.expired:
        return 'expired';
    }
  }

  static ItemStatus fromString(String value) {
    switch (value) {
      case 'safe':
        return ItemStatus.safe;
      case 'warning':
        return ItemStatus.warning;
      case 'expired':
        return ItemStatus.expired;
      default:
        return ItemStatus.safe;
    }
  }
}

class Item {
  final String id;
  final String name;
  final String categoryId;
  final int quantity;
  final String unit;
  final DateTime expiryDate;
  final String storageLocation;
  final ItemStatus status;
  final String notes;
  final String deviceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category? category;

  Item({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.storageLocation,
    required this.status,
    required this.notes,
    required this.deviceId,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? '',
      quantity: json['quantity'] ?? 1,
      unit: json['unit'] ?? '',
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : DateTime.now(),
      storageLocation: json['storage_location'] ?? '',
      status: ItemStatusExtension.fromString(json['status'] ?? 'safe'),
      notes: json['notes'] ?? '',
      deviceId: json['device_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'quantity': quantity,
      'unit': unit,
      'expiry_date':
          '${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}',
      'storage_location': storageLocation,
      'status': status.value,
      'notes': notes,
      'device_id': deviceId,
    };
  }

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  Item copyWith({
    String? id,
    String? name,
    String? categoryId,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    String? storageLocation,
    ItemStatus? status,
    String? notes,
    String? deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      storageLocation: storageLocation ?? this.storageLocation,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }
}
