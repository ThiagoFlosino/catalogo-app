import 'package:flutter/material.dart';
import 'screens/barcode_scanner_home.dart'; // Ajuste o caminho conforme necessário

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey, // Atribuir o GlobalKey
      title: 'Minha Biblioteca',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BarcodeScannerHome(),
    );
  }
}
