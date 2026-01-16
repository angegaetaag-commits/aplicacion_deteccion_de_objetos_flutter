import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:close_view/presentation/screens/detector_screen.dart';
import 'package:close_view/core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configura la orientación vertical
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Pedir permisos
  await _requestPermissions();

  runApp(const CloseViewApp());
}

Future<void> _requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.microphone,
  ].request();

  if (statuses[Permission.camera]!.isDenied) {
    print("Permiso de cámara denegado");
    // Opcional: podrías mostrar un diálogo aquí explicando por qué es necesario
  }
}

class CloseViewApp extends StatelessWidget {
  const CloseViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Close View',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.acento,
        scaffoldBackgroundColor: AppColors.fondo,
        // Añadimos esto para que use el estilo moderno de botones y widgets
        useMaterial3: true,
      ),
      // QUITAMOS el 'const' de aquí si el constructor de DetectorScreen no es const
      home: DetectorScreen(),
    );
  }
}