// lib/screens/barcode_scanner_page.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/validators.dart';

class BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  late MobileScannerController cameraController;
  bool isTorchOn = false;
  CameraFacing cameraFacing = CameraFacing.back;
  bool _isScanning = true; // Flag para evitar múltiplas pops

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: cameraFacing,
      torchEnabled: isTorchOn,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() {
      isTorchOn = !isTorchOn;
    });
    cameraController.toggleTorch();
  }

  void _switchCamera() {
    setState(() {
      cameraFacing = cameraFacing == CameraFacing.back
          ? CameraFacing.front
          : CameraFacing.back;
    });
    cameraController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escaneie o Código de Barras'),
        actions: [
          IconButton(
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: _toggleTorch,
            tooltip: isTorchOn ? 'Desligar Flash' : 'Ligar Flash',
          ),
          IconButton(
            icon: Icon(
              cameraFacing == CameraFacing.back
                  ? Icons.camera_rear
                  : Icons.camera_front,
            ),
            onPressed: _switchCamera,
            tooltip: cameraFacing == CameraFacing.back
                ? 'Usar Câmera Frontal'
                : 'Usar Câmera Traseira',
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (BarcodeCapture barcodeCapture) {
          if (!_isScanning) return; // Ignora se já está escaneando

          for (final barcode in barcodeCapture.barcodes) {
            final String? code = barcode.rawValue;
            if (code != null && isValidISBN(code)) {
              _isScanning = false; // Previne múltiplas chamadas
              Navigator.pop(context, code);
              break; // Evita múltiplas detecções
            } else if (code != null) {
              // Mostra um alerta se o código não for um ISBN válido
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Código escaneado não é um ISBN válido.')),
              );
            }
          }
        },
      ),
    );
  }
}
