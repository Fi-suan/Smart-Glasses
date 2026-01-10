// Категории товаров
enum ProductCategory {
  glasses,     // Умные очки
  canes,       // Трости
  bracelets,   // Браслеты и носимые устройства
  audiobooks,  // Аудиокниги и подписки
  accessories, // Аксессуары
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.glasses:
        return 'Умные очки';
      case ProductCategory.canes:
        return 'Трости';
      case ProductCategory.bracelets:
        return 'Браслеты';
      case ProductCategory.audiobooks:
        return 'Аудиокниги';
      case ProductCategory.accessories:
        return 'Аксессуары';
    }
  }

  String get icon {
    switch (this) {
      case ProductCategory.glasses:
        return 'visibility';
      case ProductCategory.canes:
        return 'accessibility_new';
      case ProductCategory.bracelets:
        return 'watch';
      case ProductCategory.audiobooks:
        return 'headset';
      case ProductCategory.accessories:
        return 'shopping_bag';
    }
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final ProductCategory category;
  final String imageUrl;
  final List<String> features;
  final bool isAvailable;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.features = const [],
    this.isAvailable = true,
  });

  // Factory constructor for creating a Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: ProductCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ProductCategory.accessories,
      ),
      imageUrl: json['imageUrl'] as String? ?? '',
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  // Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category.toString().split('.').last,
      'imageUrl': imageUrl,
      'features': features,
      'isAvailable': isAvailable,
    };
  }

  // Formatted price with currency
  String get formattedPrice {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} ₸';
  }
}
