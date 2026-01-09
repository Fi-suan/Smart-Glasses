class Product {
  final String id;
  final String name;
  final String category;
  final int price;
  final String description;
  final String imageIcon; // For backward compatibility
  final String? imageUrl;
  final String? thumbnailUrl;
  final bool isAvailable;
  final List<String>? features;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.imageIcon = 'shopping_bag',
    this.imageUrl,
    this.thumbnailUrl,
    this.isAvailable = true,
    this.features,
  });

  // Factory constructor for creating a Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: json['price'] as int,
      description: json['description'] as String,
      imageIcon: _getCategoryIcon(json['category'] as String),
      imageUrl: json['image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  // Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'is_available': isAvailable,
      'features': features,
    };
  }

  static String _getCategoryIcon(String category) {
    switch (category) {
      case 'Очки':
        return 'visibility';
      case 'Трости':
        return 'accessibility_new';
      case 'Часы':
        return 'watch';
      default:
        return 'shopping_bag';
    }
  }
}

// Mock data
final List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'Умные очки Pro',
    category: 'Очки',
    price: 45000,
    description: 'Профессиональные умные очки с HD дисплеем, камерой 12MP и голосовым ассистентом. Время работы до 8 часов.',
    imageIcon: 'visibility',
  ),
  Product(
    id: '2',
    name: 'Умная трость GPS',
    category: 'Трости',
    price: 12000,
    description: 'Трость с GPS навигацией, датчиками препятствий и голосовыми подсказками. Водонепроницаемая.',
    imageIcon: 'accessibility_new',
  ),
  Product(
    id: '3',
    name: 'Умные часы Health',
    category: 'Часы',
    price: 25000,
    description: 'Часы с мониторингом здоровья, пульсометром, шагомером и уведомлениями. Автономность 7 дней.',
    imageIcon: 'watch',
  ),
  Product(
    id: '4',
    name: 'Очки AR Vision',
    category: 'Очки',
    price: 55000,
    description: 'AR очки с дополненной реальностью, навигацией и переводчиком в реальном времени. Premium качество.',
    imageIcon: 'remove_red_eye',
  ),
  Product(
    id: '5',
    name: 'Умная трость Lite',
    category: 'Трости',
    price: 8000,
    description: 'Облегченная трость с базовыми датчиками и вибрацией при обнаружении препятствий.',
    imageIcon: 'accessibility',
  ),
  Product(
    id: '6',
    name: 'Часы Sport Pro',
    category: 'Часы',
    price: 35000,
    description: 'Спортивные часы с GPS, водостойкостью 50м и множеством режимов тренировок.',
    imageIcon: 'fitness_center',
  ),
];
