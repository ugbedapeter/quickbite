class ProductModel {
  final String? id;
  final String userId;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> imageUrl;
  final DateTime createdAt;

  ProductModel({
    this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String?,
      userId: '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'] ?? '', // Use category_id and handle null
      imageUrl: (json['image_url'] is String)
          ? [json['image_url'] as String]
          : (json['image_url'] is List)
          ? List<String>.from(
              (json['image_url'] as List).map((e) => e.toString()),
            )
          : [],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'name': name,
      'description': description,
      'price': price,
      'category': category, // Use category_id for consistency
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id!;
    }
    return map;
  }

  ProductModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? price,
    String? category,
    List<String>? imageUrl,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
