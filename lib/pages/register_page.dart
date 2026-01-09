import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/tts_service.dart';
import '../services/vibration_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _auth = AuthService();
  final TtsService _tts = TtsService();
  final VibrationService _vibration = VibrationService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tts.speak("Регистрация нового пользователя");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      _vibration.error();
      _tts.speak("Заполните все поля корректно");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _vibration.buttonPress();
    _tts.speak("Выполняется регистрация");

    final result = await _auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      _vibration.buttonPress();
      _tts.speak(result.message);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      _vibration.error();
      _tts.speak(result.message);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _vibration.buttonPress();
            _tts.announceButton("Назад");
            Navigator.pop(context);
          },
          tooltip: "Назад",
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome text
                const Text(
                  'Создайте аккаунт',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Заполните данные для регистрации',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Name field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    hintText: 'Иван Иванов',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите имя';
                    }
                    if (value.length < 2) {
                      return 'Имя должно быть минимум 2 символа';
                    }
                    return null;
                  },
                  onTap: () {
                    _vibration.buttonPress();
                    _tts.speak("Поле имя");
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'your@email.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Некорректный email';
                    }
                    return null;
                  },
                  onTap: () {
                    _vibration.buttonPress();
                    _tts.speak("Поле email");
                  },
                ),
                const SizedBox(height: 16),

                // Phone field (optional)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Телефон (необязательно)',
                    hintText: '+7 900 123 45 67',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onTap: () {
                    _vibration.buttonPress();
                    _tts.speak("Поле телефон");
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    hintText: 'Минимум 6 символов',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                        _vibration.buttonPress();
                        _tts.speak(_obscurePassword ? "Пароль скрыт" : "Пароль виден");
                      },
                      tooltip: _obscurePassword ? "Показать пароль" : "Скрыть пароль",
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен быть минимум 6 символов';
                    }
                    return null;
                  },
                  onTap: () {
                    _vibration.buttonPress();
                    _tts.speak("Поле пароль");
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Подтвердите пароль',
                    hintText: 'Повторите пароль',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                        _vibration.buttonPress();
                        _tts.speak(_obscureConfirmPassword ? "Пароль скрыт" : "Пароль виден");
                      },
                      tooltip: _obscureConfirmPassword ? "Показать пароль" : "Скрыть пароль",
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Подтвердите пароль';
                    }
                    if (value != _passwordController.text) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                  onTap: () {
                    _vibration.buttonPress();
                    _tts.speak("Поле подтверждение пароля");
                  },
                ),
                const SizedBox(height: 32),

                // Register button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Зарегистрироваться',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Back to login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Уже есть аккаунт? '),
                    TextButton(
                      onPressed: () {
                        _vibration.buttonPress();
                        _tts.announceButton("Войти");
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Войти',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
