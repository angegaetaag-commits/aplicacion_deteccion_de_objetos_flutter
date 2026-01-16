import 'dart:typed_data';
import 'package:flutter_vision/flutter_vision.dart';

class ObjectDetectorService {
  late FlutterVision vision;
  bool _isModelLoaded = false;

  ObjectDetectorService() {
    vision = FlutterVision();
  }

  bool get isModelLoaded => _isModelLoaded;

  Future<void> initializeDetector() async {
    try {
      await vision.loadYoloModel(
        modelPath: 'assets/ml/yolo11n_float32.tflite',
        labels: 'assets/ml/labels.txt',
        modelVersion: "yolov11", // Usa "yolov8" ya que YOLO11 es compatible con esta arquitectura en la librería
        quantization: false,    // Cambia a true si tu modelo está cuantizado (int8)
        numThreads: 2,
        useGpu: true,
      );
      _isModelLoaded = true;
      print("✅ Modelo YOLO inicializado");
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> detectObjects(
      List<Uint8List> bytesList,
      int h,
      int w
      ) async {
    if (!_isModelLoaded) return [];

    return await vision.yoloOnFrame(
      bytesList: bytesList,
      imageHeight: h,
      imageWidth: w,
      iouThreshold: 0.4,
      confThreshold: 0.5,
      classThreshold: 0.5,
    );
  }

  Future<void> dispose() async {
    if (_isModelLoaded) {
      await vision.closeYoloModel();
      _isModelLoaded = false;
    }
  }
}