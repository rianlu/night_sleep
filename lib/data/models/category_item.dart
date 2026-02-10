class CategoryItem {
  final String id;
  final String name;
  final int sortOrder;

  CategoryItem({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sortOrder': sortOrder,
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'],
      name: map['name'],
      sortOrder: map['sortOrder'],
    );
  }

  CategoryItem copyWith({
    String? name,
    int? sortOrder,
  }) {
    return CategoryItem(
      id: id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
