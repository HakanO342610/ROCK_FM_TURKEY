import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';

/// Tek seferlik QR tarama ekranı. İlk geçerli barkod yakalandığında
/// kapanır ve Navigator.pop ile string değerini döndürür.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _captured = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_captured) return;
    final code = capture.barcodes.firstWhere(
      (b) => b.rawValue != null && b.rawValue!.isNotEmpty,
      orElse: () => const Barcode(),
    ).rawValue;
    if (code == null || code.isEmpty) return;
    _captured = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: const Text(
          'QR KOD TARA',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              final torchOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: torchOn ? 'Flaş kapalı' : 'Flaş açık',
                icon: Icon(
                  torchOn ? Icons.flash_on : Icons.flash_off,
                  color: AppColors.gold,
                ),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Tarama kareleri overlay
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold),
              ),
              child: const Text(
                'Hakan abinin gönderdiği QR kodu çerçeveye doğrult.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
