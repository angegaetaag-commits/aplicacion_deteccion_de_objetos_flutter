import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:close_view/main.dart'; // Asegúrate de que este import sea correcto

void main() {
  testWidgets('CloseView Smoke Test', (WidgetTester tester) async {
    // Construye nuestra app y dispara un frame.
    await tester.pumpWidget(const CloseViewApp());

    // Verifica que el título de la app aparezca en pantalla
    expect(find.text('CLOSE VIEW'), findsOneWidget);
  });
}