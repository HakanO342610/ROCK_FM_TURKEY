import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'screens/player_screen.dart';
import 'screens/splash_screen.dart';
import 'services/admin_service.dart';
import 'services/history_service.dart';
import 'services/now_playing_service.dart';
import 'services/player_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter framework hatası → boş ekran yerine kırmızı banner üzerinde
  // hata mesajı göster (debug + release). Production'da en azından bir
  // şey görünür kalır.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFE53935), size: 48),
              const SizedBox(height: 12),
              const Text('Bir hata oluştu',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  };

  // just_audio_background beta paketi Android'de _audioHandler LateInitError
  // veriyor (emulator + Abdullah'ın telefonunda doğrulandı). iOS'ta sorunsuz
  // çalışıyor → kilit ekran kontrollerini iOS için koru, Android için skip.
  // Android tarafı için MediaItem tag'i de PlayerService'te kullanılmıyor.
  if (Platform.isIOS) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.rockfmturkey.audio',
        androidNotificationChannelName: 'RockFM Turkey',
        androidNotificationOngoing: true,
      );
    } catch (e, st) {
      debugPrint('JustAudioBackground.init FAILED (iOS): $e\n$st');
    }
  }

  // 1) HistoryService — SQLite ile şarkı geçmişi & favoriler
  final history = HistoryService();
  try {
    await history.init();
  } catch (e, st) {
    debugPrint('HistoryService.init FAILED: $e\n$st');
  }

  // 3) AdminService — secure storage ile API key
  final admin = AdminService();
  try {
    await admin.load();
  } catch (e, st) {
    debugPrint('AdminService.load FAILED: $e\n$st');
  }

  runApp(RockFMApp(history: history, admin: admin));
}

class RockFMApp extends StatelessWidget {
  final HistoryService history;
  final AdminService admin;
  const RockFMApp({super.key, required this.history, required this.admin});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerService()..init()),
        ChangeNotifierProvider.value(value: history),
        ChangeNotifierProvider(
          create: (_) => NowPlayingService(history: history)..start(),
        ),
        ChangeNotifierProvider.value(value: admin),
      ],
      child: MaterialApp(
        title: 'RockFM Turkey',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const _Boot(),
      ),
    );
  }
}

class _Boot extends StatefulWidget {
  const _Boot();
  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
