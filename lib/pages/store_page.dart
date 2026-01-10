import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../data/products_data.dart';
import '../services/cart_service.dart';
import '../services/tts_service.dart';
import '../services/vibration_service.dart';
import 'payment_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final TtsService _tts = TtsService();
  final VibrationService _vibration = VibrationService();

  // Используем реальный каталог товаров
  final List<Product> _products = ProductsData.allProducts;

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
              _tts.speak("${product.name}. Цена ${product.formattedPrice}. ${product.description}");
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Градиент категории
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: _getGradientForCategory(product.category),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _getGradientForCategory(product.category).colors.first.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getCategoryInitials(product.category),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                              product.formattedPrice,
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
                      onPressed: () async {
                        if (isInCart) {
                          await _vibration.buttonPress();
                          cart.removeFromCart(product.id);
                          _tts.speak("${product.name} удалён из корзины");
                        } else {
                          await _vibration.confirmation(); // Двойная короткая для подтверждения
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

  LinearGradient _getGradientForCategory(ProductCategory category) {
    switch (category) {
      case ProductCategory.glasses:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // Темно-синий -> синий
        );
      case ProductCategory.canes:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF065F46), Color(0xFF10B981)], // Темно-зеленый -> зеленый
        );
      case ProductCategory.bracelets:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C2D12), Color(0xFFF97316)], // Темно-оранжевый -> оранжевый
        );
      case ProductCategory.audiobooks:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF581C87), Color(0xFFA855F7)], // Темно-фиолетовый -> фиолетовый
        );
      case ProductCategory.accessories:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF374151), Color(0xFF6B7280)], // Темно-серый -> серый
        );
    }
  }

  String _getCategoryInitials(ProductCategory category) {
    switch (category) {
      case ProductCategory.glasses:
        return 'УО'; // Умные Очки
      case ProductCategory.canes:
        return 'Т'; // Трости
      case ProductCategory.bracelets:
        return 'Б'; // Браслеты
      case ProductCategory.audiobooks:
        return 'А'; // Аудиокниги
      case ProductCategory.accessories:
        return 'Д'; // Дополнительно
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

    _tts.speak("В корзине ${cart.itemCount} товаров на сумму ${_formatPrice(cart.totalPrice)}");

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
                      subtitle: Text('${item.product.formattedPrice} x ${item.quantity}'),
                      trailing: Text(
                        _formatPrice(item.totalPrice),
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
                    _formatPrice(cart.totalPrice),
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

    _tts.speak("Оформление заказа. Общая сумма ${_formatPrice(cart.totalPrice)}. Подтвердите заказ.");

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
              'Сумма: ${_formatPrice(cart.totalPrice)}',
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
            onPressed: () async {
              await _vibration.buttonPress();
              _tts.announceButton("Перейти к оплате");
              Navigator.pop(context);

              // Переход на страницу оплаты
              final paymentSuccess = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentPage(
                    amount: cart.totalPrice,
                    itemCount: cart.itemCount,
                  ),
                ),
              );

              // Если оплата прошла успешно
              if (paymentSuccess == true && mounted) {
                cart.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заказ успешно оформлен! Ожидайте звонка.'),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Перейти к оплате'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} ₸';
  }
}
