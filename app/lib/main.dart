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
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.rockfmturkey.audio',
    androidNotificationChannelName: 'RockFM Turkey',
    androidNotificationOngoing: true,
  );

  final history = HistoryService();
  await history.init();

  runApp(RockFMApp(history: history));
}

class RockFMApp extends StatelessWidget {
  final HistoryService history;
  const RockFMApp({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerService()..init()),
        ChangeNotifierProvider.value(value: history),
        ChangeNotifierProvider(
          create: (_) => NowPlayingService(history: history)..start(),
        ),
        ChangeNotifierProvider(create: (_) => AdminService()),
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
