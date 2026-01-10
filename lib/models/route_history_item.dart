class RouteHistoryItem {
  final String destination;
  final String destinationAddress;
  final DateTime timestamp;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String? distance;
  final String? duration;

  RouteHistoryItem({
    required this.destination,
    required this.destinationAddress,
    required this.timestamp,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    this.distance,
    this.duration,
  });

  // Преобразование в JSON для сохранения
  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'destinationAddress': destinationAddress,
      'timestamp': timestamp.toIso8601String(),
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'distance': distance,
      'duration': duration,
    };
  }

  // Преобразование из JSON
  factory RouteHistoryItem.fromJson(Map<String, dynamic> json) {
    return RouteHistoryItem(
      destination: json['destination'] as String,
      destinationAddress: json['destinationAddress'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      startLat: json['startLat'] as double,
      startLng: json['startLng'] as double,
      endLat: json['endLat'] as double,
      endLng: json['endLng'] as double,
      distance: json['distance'] as String?,
      duration: json['duration'] as String?,
    );
  }

  // Форматированная дата для отображения
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Сегодня ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
}
