import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/datasources/object_detector_service.dart';

class DetectorScreen extends StatefulWidget {
  @override
  _DetectorScreenState createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  late CameraController controller;
  late ObjectDetectorService detectorService;
  final FlutterTts flutterTts = FlutterTts();

  List<Map<String, dynamic>> detections = [];
  bool isProcessing = false;
  bool isCameraInitialized = false;
  bool isFastMode = true;

  @override
  void initState() {
    super.initState();
    detectorService = ObjectDetectorService();
    _setupTts();
    _initialize();
  }

  void _setupTts() async {
    await flutterTts.setLanguage("es-MX");
    await flutterTts.setSpeechRate(0.5);
  }

  void _initialize() async {
    final cameras = await availableCameras();
    controller = CameraController(
        cameras[0],
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420
    );

    await controller.initialize();
    await detectorService.initializeDetector();

    controller.startImageStream((CameraImage image) async {
      if (!isProcessing && detectorService.isModelLoaded) {
        isProcessing = true;
        final List<Uint8List> planes = image.planes.map((p) => p.bytes).toList();
        final results = await detectorService.detectObjects(planes, image.height, image.width);

        if (mounted) {
          setState(() {
            detections = results;
            isProcessing = false;
          });
        }
      }
    });
    setState(() => isCameraInitialized = true);
  }

  void _toggleMode() async {
    setState(() => isFastMode = !isFastMode);
    await flutterTts.speak(isFastMode ? "Modo rápido" : "Modo detallado");
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("CLOSE VIEW"),
        actions: [
          IconButton(
            icon: Icon(isFastMode ? Icons.bolt : Icons.remove_red_eye),
            onPressed: _toggleMode,
          )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          if (isFastMode)
            CustomPaint(
              painter: YoloPainter(
                detections: detections,
                previewSize: controller.value.previewSize!,
                screenSize: size,
              ),
            )
          else
            ...detections.map((d) => _buildDetailedBox(d, size)).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailedBox(Map<String, dynamic> d, Size size) {
    final box = d['box'];
    final double scaleX = size.width / controller.value.previewSize!.height;
    final double scaleY = size.height / controller.value.previewSize!.width;

    return Positioned(
      left: box[0] * scaleX,
      top: box[1] * scaleY,
      child: Container(
        width: (box[2] - box[0]) * scaleX,
        height: (box[3] - box[1]) * scaleY,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "${d['tag']} ${(box[4] * 100).toStringAsFixed(0)}%",
          style: const TextStyle(color: Colors.white, backgroundColor: Colors.black54),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    detectorService.dispose();
    flutterTts.stop();
    super.dispose();
  }
}

class YoloPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Size previewSize;
  final Size screenSize;

  YoloPainter({required this.detections, required this.previewSize, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3.0..color = Colors.greenAccent;
    final double scaleX = screenSize.width / previewSize.height;
    final double scaleY = screenSize.height / previewSize.width;

    for (var d in detections) {
      final box = d['box'];
      final rect = Rect.fromLTRB(box[0] * scaleX, box[1] * scaleY, box[2] * scaleX, box[3] * scaleY);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
      final tp = TextPainter(
        text: TextSpan(text: d['tag'], style: const TextStyle(color: Colors.white, backgroundColor: Colors.black54)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}