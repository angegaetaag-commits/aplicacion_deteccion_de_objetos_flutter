import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:close_view/data/datasources/object_detector_service.dart';

class DetectorScreen extends StatefulWidget {
  @override
  _DetectorScreenState createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  // --- SECCIÓN 1: VARIABLES DE CONTROL ---
  late CameraController controller;
  late ObjectDetectorService detectorService;
  final FlutterTts flutterTts = FlutterTts();

  List<Map<String, dynamic>> detections = [];
  bool isProcessing = false;
  bool isCameraInitialized = false;
  bool isFastMode = true;

  // --- SECCIÓN 2: VARIABLES DE MEMORIA (VOZ) ---
  String _ultimoObjeto = "";
  DateTime _ultimaVez = DateTime.now();
  bool _estaHablando = false;

  @override
  void initState() {
    super.initState();
    detectorService = ObjectDetectorService();
    _setupTts();
    _initialize();
  }

  // --- SECCIÓN 3: CONFIGURACIÓN INICIAL ---
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
      _procesarFrame(image);
    });
    setState(() => isCameraInitialized = true);
  }

  // --- SECCIÓN 4: LÓGICA DE PROCESAMIENTO ---
  void _procesarFrame(CameraImage image) async {
    if (isProcessing || !detectorService.isModelLoaded) return;

    isProcessing = true;
    final results = await detectorService.detectObjects(
      image.planes.map((p) => p.bytes).toList(),
      image.height,
      image.width,
    );

    if (mounted) {
      setState(() {
        detections = results;
        isProcessing = false;
      });

      // Si hay resultados, intentamos hablar
      if (results.isNotEmpty) {
        _gestionarVoz(results);
      }
    }
  }


  // --- SECCIÓN 5: LÓGICA DE NARRACIÓN (INTELIGENTE) ---
  void _gestionarVoz(List<Map<String, dynamic>> resultados) async {
    if (_estaHablando || resultados.isEmpty) return;

    final ahora = DateTime.now();

    if (ahora.difference(_ultimaVez).inSeconds > 4) {
      _estaHablando = true;

      Map<String, int> conteo = {};
      for (var res in resultados) {
        if (res['box'][4] > 0.65) {
          String nombre = _traducirEtiqueta(res['tag']);
          conteo[nombre] = (conteo[nombre] ?? 0) + 1;
        }
      }

      if (conteo.isEmpty) {
        _estaHablando = false;
        return;
      }

      List<String> frases = [];
      conteo.forEach((nombre, cantidad) {
        // 1. Convertimos el número 1 a "una" o "un"
        String cantidadTexto = cantidad.toString();
        if (cantidad == 1) {
          cantidadTexto = (nombre == "persona" || nombre == "botella" || nombre == "taza" || nombre == "mochila" || nombre == "computadora")
              ? "una"
              : "un";
        }

        // 2. Regla de plurales (es para palabras que terminan en 'r' como celular)
        String nombreFinal = nombre;
        if (cantidad > 1) {
          nombreFinal = nombre.endsWith('r') ? "${nombre}es" : "${nombre}s";
        }

        frases.add("$cantidadTexto $nombreFinal");
      });

      // 3. Unimos todo con comas y una "y" al final
      String mensajeFinal = "Veo ";
      if (frases.length == 1) {
        mensajeFinal += frases[0];
      } else {
        String ultimo = frases.removeLast();
        mensajeFinal += frases.join(", ") + " y " + ultimo;
      }

      await flutterTts.speak(mensajeFinal);

      _ultimaVez = ahora;
      _estaHablando = false;
    }
  }
  // --- SECCIÓN 6: TRADUCTOR ---
  String _traducirEtiqueta(String tag) {
    Map<String, String> diccionario = {
      'person': 'persona',
      'cell phone': 'celular',
      'bottle': 'botella',
      'chair': 'silla',
      'cup': 'taza',
      'laptop': 'computadora',
      'tv': 'television',
      'backpack': 'mochila',
      'handbag': 'bolsa',
      'umbrella': 'paraguas'
    };
    return diccionario[tag] ?? tag; // Si no está en el mapa, lo dice en inglés
  }

  // --- SECCIÓN 7: CAMBIO DE MODO ---
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
            color: isFastMode ? Colors.yellowAccent : Colors.greenAccent,
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
          "${_traducirEtiqueta(d['tag'])} ${(box[4] * 100).toStringAsFixed(0)}%",
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

// --- SECCIÓN 8: EL PINTOR (CANVAS) ---
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
        text: TextSpan(
            text: d['tag'],
            style: const TextStyle(color: Colors.white, backgroundColor: Colors.black54)
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}