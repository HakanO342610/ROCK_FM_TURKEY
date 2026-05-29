import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_service.dart';
import '../services/history_service.dart';
import '../services/now_playing_service.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import 'admin_login_screen.dart';
import 'admin_home_screen.dart';
import 'list_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final nowPlaying = context.watch<NowPlayingService>().current;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _BrandMark(),
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.gold),
                    onPressed: () => _showInfoSheet(context),
                  ),
                ],
              ),
              const Spacer(),
              _CoverArt(art: nowPlaying?.art),
              const SizedBox(height: 36),
              const _LiveBadge(),
              const SizedBox(height: 14),
              Text(
                nowPlaying?.title ?? 'Canlı Yayın',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                nowPlaying?.artist ?? 'RockFM Turkey',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.gold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              _PlayButton(service: player),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomAction(
                    icon: Icons.history,
                    label: 'GEÇMİŞ',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ListScreen(
                          title: 'GEÇMİŞ',
                          favoritesOnly: false,
                        ),
                      ),
                    ),
                  ),
                  _BottomAction(
                    icon: Icons.favorite_border,
                    label: 'FAVORİLER',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ListScreen(
                          title: 'FAVORİLER',
                          favoritesOnly: true,
                        ),
                      ),
                    ),
                  ),
                  _BottomAction(
                    icon: Icons.favorite,
                    label: 'FAVORİYE EKLE',
                    onTap: nowPlaying == null
                        ? null
                        : () => _favoriteCurrent(context, nowPlaying),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverArt extends StatelessWidget {
  final String? art;
  const _CoverArt({this.art});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: art != null && art!.isNotEmpty
          ? Image.network(
              art!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _CoverFallback(),
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const _CoverFallback(),
            )
          : const _CoverFallback(),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(Icons.graphic_eq, size: 110, color: AppColors.gold),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.gold, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _LiveDot(),
          SizedBox(width: 6),
          Text(
            'CANLI · ŞİMDİ ÇALIYOR',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.gold,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFE53935),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.music_note, color: AppColors.gold, size: 22),
        SizedBox(width: 8),
        Text('ROCKFM',
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            )),
        SizedBox(width: 4),
        Text('TURKEY',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            )),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final PlayerService service;
  const _PlayButton({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: service.player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final processing = state?.processingState;
        final playing = state?.playing ?? false;
        final loading = processing == ProcessingState.loading ||
            processing == ProcessingState.buffering;

        return GestureDetector(
          onTap: loading ? null : service.toggle,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                : Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 54,
                  ),
          ),
        );
      },
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _BottomAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Icon(icon,
                color: disabled ? AppColors.border : AppColors.textPrimary,
                size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: disabled ? AppColors.border : AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showInfoSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: AppColors.gold),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.music_note, color: AppColors.gold, size: 28),
                SizedBox(width: 10),
                Text('ROCKFM TURKEY',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 18,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Türkiye'nin rock'a kanal açan radyosu — 7/24 canlı yayın.",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _InfoTile(
              icon: Icons.public,
              label: 'rockfmturkey.com',
              onTap: () => launchUrl(
                Uri.parse('https://rockfmturkey.com'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            _InfoTile(
              icon: Icons.mail_outline,
              label: 'iletisim@rockfmturkey.com',
              onTap: () => launchUrl(
                Uri.parse('mailto:iletisim@rockfmturkey.com'),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            Consumer<AdminService>(
              builder: (_, admin, _) => _InfoTile(
                icon: admin.isLoggedIn
                    ? Icons.admin_panel_settings
                    : Icons.lock_outline,
                label: admin.isLoggedIn ? 'Admin Paneli' : 'Admin Girişi',
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => admin.isLoggedIn
                          ? const AdminHomeScreen(welcomeName: 'Admin')
                          : const AdminLoginScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Sürüm 1.0.0',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _InfoTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  )),
            ),
            const Icon(Icons.open_in_new, color: AppColors.gold, size: 16),
          ],
        ),
      ),
    );
  }
}

Future<void> _favoriteCurrent(BuildContext context, dynamic np) async {
  final history = context.read<HistoryService>();
  await history.recordIfChanged(np);
  final entry = history.history.firstWhere(
    (e) => e.title == np.title && e.artist == np.artist,
    orElse: () => history.history.isNotEmpty
        ? history.history.first
        : throw StateError('Henüz şarkı geçmişe eklenmedi'),
  );
  if (!entry.favorite) {
    await history.toggleFavorite(entry);
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(
          '${np.title} favorilere eklendi',
          style: const TextStyle(color: AppColors.gold),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
