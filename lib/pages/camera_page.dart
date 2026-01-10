import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gpt_vision_service.dart';
import '../services/tts_service.dart';
import '../services/vibration_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final GptVisionService _visionService = GptVisionService();
  final TtsService _tts = TtsService();
  final VibrationService _vibration = VibrationService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  String? _description;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _tts.speak("Камера открыта. Нажмите большую кнопку чтобы узнать что впереди.");
  }

  Future<void> _captureAndAnalyze() async {
    try {
      await _vibration.buttonPress();
      await _tts.speak("Делаю снимок");

      // Захват изображения с камеры
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) {
        await _tts.speak("Снимок не сделан");
        return;
      }

      setState(() {
        _imageFile = File(image.path);
        _isAnalyzing = true;
        _description = null;
      });

      await _tts.speak("Анализирую изображение. Ожидайте.");

      // Комплексный анализ через GPT-4 Vision (или mock)
      String description;
      if (_visionService.hasApiKey) {
        description = await _visionService.describeScene(_imageFile!);
      } else {
        description = await _visionService.analyzeMock(type: AnalysisType.sceneDescription);
      }

      setState(() {
        _description = description;
        _isAnalyzing = false;
      });

      // Вибрация при обнаружении препятствий
      if (description.contains('ОПАСНОСТЬ!') || description.contains('ОПАСНОСТЬ')) {
        await _vibration.sos(); // SOS паттерн для критической опасности
        debugPrint('🚨 ОПАСНОСТЬ обнаружена! SOS вибрация');
      } else if (description.contains('ВНИМАНИЕ')) {
        await _vibration.obstacleDetected(isDangerous: false); // Предупреждение
      }

      // Озвучиваем результат
      await _tts.speak(description);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      await _vibration.error();
      await _tts.speak("Ошибка при анализе изображения");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Что впереди?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _tts.announceButton("Назад");
            Navigator.pop(context);
          },
          tooltip: "Назад",
        ),
      ),
      body: Column(
        children: [
          // Область камеры/результата
          Expanded(
            child: Container(
              color: Colors.black,
              child: _isAnalyzing
                  ? _buildAnalyzingView()
                  : _imageFile == null
                      ? _buildInitialView()
                      : Stack(
                          children: [
                            // Изображение
                            Positioned.fill(
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Оверлей с результатом
                            if (_description != null)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.9),
                                        Colors.black.withOpacity(0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _description!.contains('ОПАСНОСТЬ')
                                                ? Icons.warning
                                                : Icons.visibility,
                                            color: _description!.contains('ОПАСНОСТЬ')
                                                ? Colors.red
                                                : Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Анализ сцены:',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: _description!.contains('ОПАСНОСТЬ')
                                                    ? Colors.red
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.volume_up),
                                            color: Colors.white,
                                            onPressed: () {
                                              _vibration.buttonPress();
                                              _tts.speak(_description!);
                                            },
                                            tooltip: "Повторить",
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        constraints: const BoxConstraints(maxHeight: 200),
                                        child: SingleChildScrollView(
                                          child: Text(
                                            _description!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
            ),
          ),

          // Большая кнопка внизу
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: _isAnalyzing ? null : _captureAndAnalyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isAnalyzing ? Icons.hourglass_empty : Icons.camera_alt,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isAnalyzing ? 'Анализирую...' : 'Что впереди?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'AI анализирует: препятствия, переходы, текст, сцену',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 4,
        ),
        const SizedBox(height: 24),
        const Text(
          'Анализирую изображение...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'AI проверяет препятствия, переходы,\nтекст и общую сцену',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInitialView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt,
          size: 100,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(height: 24),
        Text(
          'Нажмите кнопку внизу\nчтобы узнать что впереди',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 20,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'AI автоматически проверит:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(Icons.warning, 'Препятствия и опасности'),
              _buildFeatureItem(Icons.traffic, 'Пешеходные переходы'),
              _buildFeatureItem(Icons.text_fields, 'Текст и вывески'),
              _buildFeatureItem(Icons.visibility, 'Общая сцена'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
