import 'package:camera/camera.dart';

class CameraDataSource {
  CameraController? _controller;
  bool _isProcessing = false;

  Future<void> initializeCamera(Function(CameraImage) onFrameAvailable) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.medium, // Resolución media para IA (más rápido)
      enableAudio: false,
    );

    await _controller!.initialize();

    // Iniciamos el flujo de imágenes en tiempo real
    _controller!.startImageStream((CameraImage image) {

      if (_isProcessing) return;

      _isProcessing = true;


      onFrameAvailable(image);
      _isProcessing = false;
    });
  }

  CameraController? get controller => _controller;

  void dispose() {
    _controller?.dispose();
  }
}