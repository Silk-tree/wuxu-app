class Category {
  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '📦',
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'sort_order': sortOrder,
    };
  }
}
