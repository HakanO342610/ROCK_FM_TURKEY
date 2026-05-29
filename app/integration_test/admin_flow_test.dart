import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'package:rockfm_turkey/screens/player_screen.dart';
import 'package:rockfm_turkey/services/admin_service.dart';
import 'package:rockfm_turkey/services/history_service.dart';
import 'package:rockfm_turkey/services/now_playing_service.dart';
import 'package:rockfm_turkey/services/player_service.dart';
import 'package:rockfm_turkey/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.rockfmturkey.audio.test',
      androidNotificationChannelName: 'RockFM Turkey Test',
      androidNotificationOngoing: true,
    );
  });

  Widget buildApp(HistoryService history) {
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
        theme: AppTheme.dark(),
        debugShowCheckedModeBanner: false,
        home: const PlayerScreen(),
      ),
    );
  }

  testWidgets('player ekranı yüklenir, ana öğeler görünür', (tester) async {
    final history = HistoryService();
    await history.init();
    await tester.pumpWidget(buildApp(history));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('ROCKFM'), findsOneWidget);
    expect(find.text('TURKEY'), findsOneWidget);
    expect(find.text('CANLI · ŞİMDİ ÇALIYOR'), findsOneWidget);
    expect(find.text('GEÇMİŞ'), findsOneWidget);
    expect(find.text('FAVORİLER'), findsOneWidget);
    expect(find.text('FAVORİYE EKLE'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('sağ üst menü tıklanır → info sheet açılır (eski bug fix doğrulama)', (tester) async {
    final history = HistoryService();
    await history.init();
    await tester.pumpWidget(buildApp(history));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('ROCKFM TURKEY'), findsWidgets);
    expect(find.text('rockfmturkey.com'), findsOneWidget);
    expect(find.textContaining('Sürüm'), findsOneWidget);
  });

  testWidgets('logo 7-tap → admin şifre dialogu açılır', (tester) async {
    final history = HistoryService();
    await history.init();
    await tester.pumpWidget(buildApp(history));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final brand = find.text('ROCKFM');
    for (int i = 0; i < 7; i++) {
      await tester.tap(brand);
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();

    expect(find.text('ADMIN GİRİŞİ'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('admin dialog: yanlış şifre → hata mesajı', (tester) async {
    final history = HistoryService();
    await history.init();
    await tester.pumpWidget(buildApp(history));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final brand = find.text('ROCKFM');
    for (int i = 0; i < 7; i++) {
      await tester.tap(brand);
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hatali-sifre');
    await tester.tap(find.text('GİRİŞ'));
    await tester.pump();

    expect(find.text('Hatalı şifre'), findsOneWidget);
  });

  testWidgets('admin dialog: doğru şifre → ADMIN PANELİ açılır', (tester) async {
    final history = HistoryService();
    await history.init();
    await tester.pumpWidget(buildApp(history));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final brand = find.text('ROCKFM');
    for (int i = 0; i < 7; i++) {
      await tester.tap(brand);
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), AdminService.adminPassword);
    await tester.tap(find.text('GİRİŞ'));
    await tester.pumpAndSettle();

    expect(find.text('ADMIN PANELİ'), findsOneWidget);
    expect(find.text('YAYIN AKTİF'), findsOneWidget);
    expect(find.textContaining('Şarkı Yükle'), findsOneWidget);
    expect(find.text('Public Player'), findsOneWidget);
    expect(find.text('Playlist Yönetimi'), findsOneWidget);
    expect(find.text('Dinleyici İstatistikleri'), findsOneWidget);
  });

  testWidgets('admin tap timeout: yavaş tıklama → dialog AÇILMAZ', (tester) async {
    final history = HistoryService();
    await history.init();
    await tester.pumpWidget(buildApp(history));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final brand = find.text('ROCKFM');
    // 5 hızlı tap + 4sn bekle (tapTimeout 3sn) + 3 tap → counter sıfırlanmış olmalı
    for (int i = 0; i < 5; i++) {
      await tester.tap(brand);
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump(const Duration(seconds: 4));
    for (int i = 0; i < 3; i++) {
      await tester.tap(brand);
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();

    // 7'ye ulaşılmadığı için dialog görünmemeli
    expect(find.text('ADMIN GİRİŞİ'), findsNothing);
  });
}
