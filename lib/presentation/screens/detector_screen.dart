import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:close_view/data/datasources/object_detector_service.dart';

class DetectorScreen extends StatefulWidget {
  @override
  _DetectorScreenState createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  late CameraController controller;
  late ObjectDetectorService detectorService;
  List<Map<String, dynamic>> detections = [];
  bool isProcessing = false;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    detectorService = ObjectDetectorService();
    _initialize();
  }

  void _initialize() async {
    // 1. Inicializar Cámara
    final cameras = await availableCameras();
    controller = CameraController(
      cameras[0],
      ResolutionPreset.low, // Medium es mejor para no saturar el procesador
      enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420
    );

    await controller.initialize();

    // 2. Inicializar el Modelo YOLO
    await detectorService.initializeDetector();

    // 3. Empezar el flujo de imágenes
    controller.startImageStream((CameraImage image) async {
      if (!isProcessing && detectorService.isModelLoaded) {
        setState(() => isProcessing = true);

        // Convertimos los planos de la cámara a la lista de bytes que pide flutter_vision
        final List<Uint8List> planes = image.planes.map((plane) => plane.bytes).toList();

        final results = await detectorService.detectObjects(
          planes,
          image.height,
          image.width,
        );

        if (results.isNotEmpty) {
          setState(() {
            detections = results;
          });
        }

        setState(() => isProcessing = false);
      }
    });

    setState(() => isCameraInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Obtenemos el tamaño de la pantalla para ajustar los cuadros
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("Close View - Detector")),
      body: Stack(
        children: [
          // 1. La cámara de fondo
          CameraPreview(controller),

          // 2. Dibujar los cuadros (Bounding Boxes)
          ...detections.map((d) {
            // flutter_vision devuelve el box como [x1, y1, x2, y2, confianza]
            final box = d['box'];
            return Positioned(
              left: box[0] * (size.width / controller.value.previewSize!.height),
              top: box[1] * (size.height / controller.value.previewSize!.width),
              child: Container(
                width: (box[2] - box[0]) * (size.width / controller.value.previewSize!.height),
                height: (box[3] - box[1]) * (size.height / controller.value.previewSize!.width),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${d['tag']} ${(box[4] * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    detectorService.dispose();
    super.dispose();
  }
}