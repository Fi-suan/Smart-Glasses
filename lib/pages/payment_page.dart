import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tts_service.dart';
import '../services/vibration_service.dart';

class PaymentPage extends StatefulWidget {
  final double amount;
  final int itemCount;

  const PaymentPage({
    super.key,
    required this.amount,
    required this.itemCount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TtsService _tts = TtsService();
  final VibrationService _vibration = VibrationService();
  final _formKey = GlobalKey<FormState>();

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tts.speak("Оплата заказа. Сумма ${_formatPrice(widget.amount)}. Введите данные карты.");
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} ₸';
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String value) {
    value = value.replaceAll('/', '');
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _vibration.buttonPress();
            _tts.announceButton("Назад");
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Информация о заказе
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Итого к оплате',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatPrice(widget.amount),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Товаров: ${widget.itemCount}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Номер карты
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Номер карты',
                  hintText: '0000 0000 0000 0000',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                onChanged: (value) {
                  final formatted = _formatCardNumber(value);
                  if (formatted != value) {
                    _cardNumberController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                onTap: () {
                  _vibration.buttonPress();
                  _tts.speak("Поле ввода номера карты");
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер карты';
                  }
                  final digits = value.replaceAll(' ', '');
                  if (digits.length != 16) {
                    return 'Номер карты должен содержать 16 цифр';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Срок действия и CVV
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: InputDecoration(
                        labelText: 'Срок',
                        hintText: 'MM/ГГ',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (value) {
                        final formatted = _formatExpiry(value);
                        if (formatted != value) {
                          _expiryController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                      onTap: () {
                        _vibration.buttonPress();
                        _tts.speak("Поле ввода срока действия карты");
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите срок';
                        }
                        final digits = value.replaceAll('/', '');
                        if (digits.length != 4) {
                          return 'Формат: ММ/ГГ';
                        }
                        final month = int.tryParse(digits.substring(0, 2));
                        if (month == null || month < 1 || month > 12) {
                          return 'Неверный месяц';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '000',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onTap: () {
                        _vibration.buttonPress();
                        _tts.speak("Поле ввода CVV кода");
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите CVV';
                        }
                        if (value.length != 3) {
                          return '3 цифры';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Имя держателя карты
              TextFormField(
                controller: _cardHolderController,
                decoration: InputDecoration(
                  labelText: 'Имя держателя карты',
                  hintText: 'IVANOV IVAN',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z\s]')),
                ],
                onTap: () {
                  _vibration.buttonPress();
                  _tts.speak("Поле ввода имени держателя карты");
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя держателя';
                  }
                  if (value.length < 3) {
                    return 'Слишком короткое имя';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Кнопка оплаты
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Оплатить ${_formatPrice(widget.amount)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Информация о безопасности
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Безопасная оплата',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      _tts.speak("Проверьте правильность заполнения всех полей");
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    _vibration.buttonPress();
    _tts.speak("Обработка платежа. Пожалуйста, подождите.");

    // Симуляция обработки платежа
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
    });

    // Симулируем успешную оплату
    await _vibration.success();
    _tts.speak("Оплата прошла успешно! Заказ оформлен.");

    if (mounted) {
      Navigator.pop(context, true); // Возвращаем true при успешной оплате
    }
  }
}
