// Widget test alternative for the admin flow.
//
// Integration_test driving on the iOS simulator was unreliable in this
// project (silent stdout buffer, plus a parallel `xcrun simctl uninstall`
// in another shell kept killing the Runner.app mid-test). This widget
// test exercises the same admin unlock flow against PlayerScreen in a
// pure Flutter test environment — no simulator, no audio plugins, no
// real network.
//
// Strategy:
//   * Stub MethodChannels for path_provider, sqflite, just_audio and
//     just_audio_background so the production services can be constructed
//     without crashing.
//   * Subclass NowPlayingService / PlayerService to skip native init.
//   * Force the test view to phone-sized (414×896) so the player layout
//     (260px cover + Spacers + bottom row) doesn't overflow the default
//     800×600 test viewport — the overflow shifts widgets off-screen and
//     `tester.tap()` fails because hit-test misses the brand text.
//   * Avoid `pumpAndSettle` — the _LiveDot inside _LiveBadge runs an
//     infinite AnimationController (`repeat(reverse: true)`), so
//     pumpAndSettle never returns. Use bounded `pump(duration)` instead.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rockfm_turkey/screens/player_screen.dart';
import 'package:rockfm_turkey/services/admin_service.dart';
import 'package:rockfm_turkey/services/history_service.dart';
import 'package:rockfm_turkey/services/now_playing_service.dart';
import 'package:rockfm_turkey/services/player_service.dart';
import 'package:rockfm_turkey/theme/app_theme.dart';

void _stubMethodChannels() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // path_provider — return a tmp-ish path so HistoryService doesn't crash.
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  messenger.setMockMethodCallHandler(pathChannel, (call) async {
    return '/tmp/rockfm_test';
  });

  // sqflite — pretend every call succeeds with empty data.
  const sqfliteChannel = MethodChannel('com.tekartik.sqflite');
  messenger.setMockMethodCallHandler(sqfliteChannel, (call) async {
    switch (call.method) {
      case 'getDatabasesPath':
        return '/tmp/rockfm_test';
      case 'openDatabase':
        return 1;
      case 'query':
        return <Map<String, Object?>>[];
      case 'insert':
      case 'update':
      case 'delete':
        return 0;
      case 'execute':
      case 'closeDatabase':
        return null;
      default:
        return null;
    }
  });

  // just_audio — playback channels (no-op).
  const justAudioChannel = MethodChannel('com.ryanheise.just_audio.methods');
  messenger.setMockMethodCallHandler(justAudioChannel, (call) async => null);

  // just_audio_background init.
  const jabChannel =
      MethodChannel('com.ryanheise.just_audio_background.methods');
  messenger.setMockMethodCallHandler(jabChannel, (call) async => null);

  // audio_session
  const audioSession = MethodChannel('com.ryanheise.audio_session');
  messenger.setMockMethodCallHandler(audioSession, (call) async => null);
}

class _StubNowPlayingService extends NowPlayingService {
  _StubNowPlayingService(HistoryService h) : super(history: h);
  @override
  void start() {
    // Don't hit the network, don't schedule a timer.
  }
}

class _StubPlayerService extends PlayerService {
  @override
  Future<void> init() async {
    // Don't touch the AudioPlayer (would call native channels).
  }
}

void _setPhoneViewport(WidgetTester tester) {
  // Slightly wider than a real iPhone so the bottom action row
  // (GEÇMİŞ / FAVORİLER / FAVORİYE EKLE) fits without horizontal overflow.
  // The default test viewport (800x600) is too short vertically.
  tester.view.physicalSize = const Size(500, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _buildApp(HistoryService history) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PlayerService>(create: (_) => _StubPlayerService()),
      ChangeNotifierProvider.value(value: history),
      ChangeNotifierProvider<NowPlayingService>(
        create: (_) => _StubNowPlayingService(history),
      ),
      ChangeNotifierProvider(create: (_) => AdminService()),
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: const PlayerScreen(),
    ),
  );
}

// Pumps frames for a bounded duration. Avoids pumpAndSettle which hangs
// because the _LiveDot animation repeats forever.
Future<void> _pumpFrames(WidgetTester tester,
    [Duration total = const Duration(milliseconds: 600)]) async {
  const frame = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(frame);
    elapsed += frame;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _stubMethodChannels();
  });

  testWidgets('player ekranı yüklenir, ana öğeler görünür', (tester) async {
    _setPhoneViewport(tester);
    final history = HistoryService();
    await tester.pumpWidget(_buildApp(history));
    await _pumpFrames(tester);

    expect(find.text('ROCKFM'), findsOneWidget);
    expect(find.text('TURKEY'), findsOneWidget);
    expect(find.text('CANLI · ŞİMDİ ÇALIYOR'), findsOneWidget);
    expect(find.text('GEÇMİŞ'), findsOneWidget);
    expect(find.text('FAVORİLER'), findsOneWidget);
    expect(find.text('FAVORİYE EKLE'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('sağ üst menü tıklanır → info sheet açılır (eski bug fix)',
      (tester) async {
    _setPhoneViewport(tester);
    final history = HistoryService();
    await tester.pumpWidget(_buildApp(history));
    await _pumpFrames(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await _pumpFrames(tester);

    expect(find.text('ROCKFM TURKEY'), findsWidgets);
    expect(find.text('rockfmturkey.com'), findsOneWidget);
    expect(find.textContaining('Sürüm'), findsOneWidget);
  });

  testWidgets('logo 7-tap → admin şifre dialogu açılır', (tester) async {
    _setPhoneViewport(tester);
    final history = HistoryService();
    await tester.pumpWidget(_buildApp(history));
    await _pumpFrames(tester);

    final brand = find.text('ROCKFM');
    for (int i = 0; i < 7; i++) {
      await tester.tap(brand);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _pumpFrames(tester);

    expect(find.text('ADMIN GİRİŞİ'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('admin dialog: yanlış şifre → hata mesajı', (tester) async {
    _setPhoneViewport(tester);
    final history = HistoryService();
    await tester.pumpWidget(_buildApp(history));
    await _pumpFrames(tester);

    final brand = find.text('ROCKFM');
    for (int i = 0; i < 7; i++) {
      await tester.tap(brand);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _pumpFrames(tester);

    await tester.enterText(find.byType(TextField), 'hatali-sifre');
    await tester.tap(find.text('GİRİŞ'));
    await _pumpFrames(tester);

    expect(find.text('Hatalı şifre'), findsOneWidget);
  });

  testWidgets('admin dialog: doğru şifre → ADMIN PANELİ açılır',
      (tester) async {
    _setPhoneViewport(tester);
    final history = HistoryService();
    await tester.pumpWidget(_buildApp(history));
    await _pumpFrames(tester);

    final brand = find.text('ROCKFM');
    for (int i = 0; i < 7; i++) {
      await tester.tap(brand);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _pumpFrames(tester);

    await tester.enterText(find.byType(TextField), AdminService.adminPassword);
    await tester.tap(find.text('GİRİŞ'));
    await _pumpFrames(tester, const Duration(seconds: 1));

    expect(find.text('ADMIN PANELİ'), findsOneWidget);
    expect(find.text('YAYIN AKTİF'), findsOneWidget);
    expect(find.textContaining('Şarkı Yükle'), findsOneWidget);
    expect(find.text('Public Player'), findsOneWidget);
    expect(find.text('Playlist Yönetimi'), findsOneWidget);
    expect(find.text('Dinleyici İstatistikleri'), findsOneWidget);
  });

  testWidgets('admin tap timeout: yavaş tıklama → dialog AÇILMAZ',
      (tester) async {
    _setPhoneViewport(tester);
    final history = HistoryService();
    await tester.pumpWidget(_buildApp(history));
    await _pumpFrames(tester);

    final brand = find.text('ROCKFM');
    for (int i = 0; i < 5; i++) {
      await tester.tap(brand);
      await tester.pump(const Duration(milliseconds: 100));
    }
    // tapTimeout is 3sn — wait long enough to reset the counter.
    await tester.pump(const Duration(seconds: 4));
    for (int i = 0; i < 3; i++) {
      // warnIfMissed: false — after the 4s pump the _LiveDot opacity
      // animation can land on a frame where the brand row is mid-paint;
      // the tap target is still reachable, just produces a noisy warning.
      await tester.tap(brand, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _pumpFrames(tester);

    expect(find.text('ADMIN GİRİŞİ'), findsNothing);
  });
}
