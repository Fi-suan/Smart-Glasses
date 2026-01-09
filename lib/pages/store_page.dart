import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/tts_service.dart';
import '../services/vibration_service.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final TtsService _tts = TtsService();
  final VibrationService _vibration = VibrationService();

  // Mock товары
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Умные очки SmartVision Pro',
      description: 'AI камера, GPS навигация, голосовой помощник. 12 часов автономной работы.',
      price: 45000,
      imageUrl: 'https://example.com/glasses1.jpg',
      category: 'glasses',
    ),
    Product(
      id: '2',
      name: 'Умные очки EchoSight',
      description: 'Распознавание объектов, чтение текста, определение препятствий.',
      price: 35000,
      imageUrl: 'https://example.com/glasses2.jpg',
      category: 'glasses',
    ),
    Product(
      id: '3',
      name: 'Умная трость Navigate Plus',
      description: 'Вибрация при препятствиях, GPS трекер, водонепроницаемая.',
      price: 15000,
      imageUrl: 'https://example.com/cane1.jpg',
      category: 'cane',
    ),
    Product(
      id: '4',
      name: 'Умные часы VoiceTime',
      description: 'Голосовое озвучивание времени, пульсометр, SOS кнопка.',
      price: 8000,
      imageUrl: 'https://example.com/watch1.jpg',
      category: 'watch',
    ),
    Product(
      id: '5',
      name: 'Тактильный браслет AlertBand',
      description: 'Вибрационные уведомления, Bluetooth, водонепроницаемый.',
      price: 5000,
      imageUrl: 'https://example.com/band1.jpg',
      category: 'accessories',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tts.speak("Магазин умных устройств для слепых");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        actions: [
          Consumer<CartService>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      _vibration.buttonPress();
                      _tts.announceButton("Корзина");
                      _showCartDialog(context);
                    },
                    tooltip: "Корзина",
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return _buildProductCard(_products[index]);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Consumer<CartService>(
      builder: (context, cart, child) {
        final isInCart = cart.isInCart(product.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              _vibration.buttonPress();
              _tts.speak("${product.name}. Цена ${product.price} рублей. ${product.description}");
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Иконка категории
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForCategory(product.category),
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.price} ₽',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _vibration.buttonPress();
                        if (isInCart) {
                          cart.removeFromCart(product.id);
                          _tts.speak("${product.name} удалён из корзины");
                        } else {
                          cart.addToCart(product);
                          _tts.speak("${product.name} добавлен в корзину");
                        }
                      },
                      icon: Icon(
                        isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                      ),
                      label: Text(
                        isInCart ? 'Удалить из корзины' : 'Добавить в корзину',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInCart
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'glasses':
        return Icons.visibility;
      case 'cane':
        return Icons.accessible;
      case 'watch':
        return Icons.watch;
      case 'accessories':
        return Icons.bluetooth;
      default:
        return Icons.shopping_bag;
    }
  }

  void _showCartDialog(BuildContext context) {
    final cart = Provider.of<CartService>(context, listen: false);

    if (cart.items.isEmpty) {
      _tts.speak("Корзина пуста");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Корзина'),
          content: const Text('Корзина пуста'),
          actions: [
            TextButton(
              onPressed: () {
                _vibration.buttonPress();
                _tts.announceButton("Закрыть");
                Navigator.pop(context);
              },
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
      return;
    }

    _tts.speak("В корзине ${cart.itemCount} товаров на сумму ${cart.totalPrice} рублей");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Корзина'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('${item.product.price} ₽ x ${item.quantity}'),
                      trailing: Text(
                        '${item.totalPrice} ₽',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Итого:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${cart.totalPrice} ₽',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _vibration.buttonPress();
              _tts.announceButton("Очистить корзину");
              cart.clear();
              _tts.speak("Корзина очищена");
              Navigator.pop(context);
            },
            child: const Text('Очистить'),
          ),
          ElevatedButton(
            onPressed: () {
              _vibration.buttonPress();
              _tts.announceButton("Оформить заказ");
              Navigator.pop(context);
              _showCheckoutDialog(context);
            },
            child: const Text('Оформить заказ'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    final cart = Provider.of<CartService>(context, listen: false);

    _tts.speak("Оформление заказа. Общая сумма ${cart.totalPrice} рублей. Подтвердите заказ.");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оформление заказа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Товаров: ${cart.itemCount}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Сумма: ${cart.totalPrice} ₽',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Доставка: Бесплатно',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Text(
              'Оплата: При получении',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _vibration.buttonPress();
              _tts.announceButton("Отмена");
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              _vibration.buttonPress();
              _tts.speak("Заказ успешно оформлен! Мы свяжемся с вами в ближайшее время.");
              cart.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Заказ оформлен! Ожидайте звонка.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Подтвердить заказ'),
          ),
        ],
      ),
    );
  }
}
