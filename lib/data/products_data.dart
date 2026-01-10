import '../models/product.dart';

class ProductsData {
  static final List<Product> allProducts = [
    // Умные очки
    Product(
      id: 'glasses_1',
      name: 'OrCam MyEye 2',
      description: 'Умные очки с искусственным интеллектом для чтения текста, распознавания лиц и продуктов',
      price: 850000,
      category: ProductCategory.glasses,
      imageUrl: 'https://via.placeholder.com/300x200/4A90E2/FFFFFF?text=OrCam+MyEye+2',
      features: [
        'Мгновенное чтение текста',
        'Распознавание лиц',
        'Идентификация продуктов',
        'Определение цветов',
        'Работа без интернета',
      ],
    ),
    Product(
      id: 'glasses_2',
      name: 'Envision Glasses',
      description: 'Умные очки на базе Google Glass для помощи слабовидящим',
      price: 620000,
      category: ProductCategory.glasses,
      imageUrl: 'https://via.placeholder.com/300x200/7B68EE/FFFFFF?text=Envision+Glasses',
      features: [
        'Распознавание текста',
        'Описание сцены через AI',
        'Сканирование штрих-кодов',
        'Голосовой помощник',
        'Работа в облаке',
      ],
    ),
    Product(
      id: 'glasses_3',
      name: 'NuEyes Pro 3',
      description: 'Профессиональные умные очки с увеличением изображения',
      price: 450000,
      category: ProductCategory.glasses,
      imageUrl: 'https://via.placeholder.com/300x200/32CD32/FFFFFF?text=NuEyes+Pro+3',
      features: [
        'Увеличение до 12x',
        'Регулировка контраста',
        'Несколько режимов просмотра',
        'Легкий вес',
        'До 4 часов работы',
      ],
    ),

    // Трости
    Product(
      id: 'cane_1',
      name: 'WeWALK Smart Cane',
      description: 'Умная трость с ультразвуковыми датчиками и GPS навигацией',
      price: 180000,
      category: ProductCategory.canes,
      imageUrl: 'https://via.placeholder.com/300x200/FF6347/FFFFFF?text=WeWALK+Cane',
      features: [
        'Обнаружение препятствий выше пояса',
        'Встроенный GPS',
        'Подключение к смартфону',
        'Вибрационные уведомления',
        'Голосовой помощник',
      ],
    ),
    Product(
      id: 'cane_2',
      name: 'UltraCane Mobility Aid',
      description: 'Электронная трость с ультразвуковыми сенсорами',
      price: 250000,
      category: ProductCategory.canes,
      imageUrl: 'https://via.placeholder.com/300x200/FFA500/FFFFFF?text=UltraCane',
      features: [
        'Два ультразвуковых датчика',
        'Дальность обнаружения до 4 метров',
        'Водонепроницаемая',
        'Складная конструкция',
        'Аккумулятор на 8 часов',
      ],
    ),
    Product(
      id: 'cane_3',
      name: 'Складная трость из карбона',
      description: 'Легкая и прочная складная трость из углеродного волокна',
      price: 25000,
      category: ProductCategory.canes,
      imageUrl: 'https://via.placeholder.com/300x200/808080/FFFFFF?text=Carbon+Cane',
      features: [
        'Вес всего 180 грамм',
        'Складывается до 30 см',
        'Прочность карбона',
        'Светоотражающие элементы',
        'Регулируемая высота',
      ],
    ),

    // Браслеты
    Product(
      id: 'bracelet_1',
      name: 'Sunu Band',
      description: 'Навигационный браслет с эхолокацией для слепых',
      price: 120000,
      category: ProductCategory.bracelets,
      imageUrl: 'https://via.placeholder.com/300x200/1E90FF/FFFFFF?text=Sunu+Band',
      features: [
        'Обнаружение препятствий',
        'Вибрационная обратная связь',
        'GPS навигация',
        'Водонепроницаемость IP67',
        'До 7 дней работы',
      ],
    ),
    Product(
      id: 'bracelet_2',
      name: 'Buzz Clip',
      description: 'Компактное устройство с ультразвуковыми датчиками',
      price: 45000,
      category: ProductCategory.bracelets,
      imageUrl: 'https://via.placeholder.com/300x200/9370DB/FFFFFF?text=Buzz+Clip',
      features: [
        'Крепится на одежду',
        'Обнаружение на расстоянии до 2.5 м',
        'Вибрационные сигналы',
        'Компактный размер',
        'Батарея на 2 недели',
      ],
    ),

    // Аудиокниги и подписки
    Product(
      id: 'audio_1',
      name: 'Подписка "Аудиокниги - Месяц"',
      description: 'Доступ к библиотеке из 10000+ аудиокниг на русском языке',
      price: 2500,
      category: ProductCategory.audiobooks,
      imageUrl: 'https://via.placeholder.com/300x200/FF1493/FFFFFF?text=1+Month',
      features: [
        '10000+ аудиокниг',
        'Новинки каждую неделю',
        'Оффлайн прослушивание',
        'Без рекламы',
        'Отмена в любой момент',
      ],
    ),
    Product(
      id: 'audio_2',
      name: 'Подписка "Аудиокниги - Год"',
      description: 'Годовой доступ к библиотеке аудиокниг со скидкой 40%',
      price: 18000,
      category: ProductCategory.audiobooks,
      imageUrl: 'https://via.placeholder.com/300x200/FF1493/FFFFFF?text=12+Months',
      features: [
        'Экономия 40%',
        'Все функции месячной подписки',
        'Эксклюзивный контент',
        'Приоритетная поддержка',
      ],
    ),

    // Аксессуары
    Product(
      id: 'acc_1',
      name: 'Тактильные этикетки (100 шт)',
      description: 'Рельефные этикетки для маркировки предметов',
      price: 3500,
      category: ProductCategory.accessories,
      imageUrl: 'https://via.placeholder.com/300x200/20B2AA/FFFFFF?text=Labels',
      features: [
        '100 этикеток',
        'Клеевая основа',
        'Разные размеры',
        'Водостойкие',
      ],
    ),
    Product(
      id: 'acc_2',
      name: 'Говорящие часы',
      description: 'Наручные часы с голосовым сообщением времени',
      price: 15000,
      category: ProductCategory.accessories,
      imageUrl: 'https://via.placeholder.com/300x200/FFD700/FFFFFF?text=Talking+Watch',
      features: [
        'Голосовое объявление времени',
        'Будильник',
        'Водонепроницаемые',
        'Крупные кнопки',
      ],
    ),
  ];

  static List<Product> getByCategory(ProductCategory category) {
    return allProducts.where((p) => p.category == category).toList();
  }

  static Product? getById(String id) {
    try {
      return allProducts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
