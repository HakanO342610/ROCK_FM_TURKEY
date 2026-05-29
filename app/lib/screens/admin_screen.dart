import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  static const _adminUrl = 'https://rockfmturkey.com';
  static const _publicPlayerUrl = 'https://rockfmturkey.com/public/rockfmturkey';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: const Text(
          'ADMIN PANELİ',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _StatusCard(),
          const SizedBox(height: 16),
          _AdminTile(
            icon: Icons.cloud_upload,
            title: 'Şarkı Yükle & Kuyruk',
            subtitle: 'AzuraCast yönetim paneline git',
            onTap: () => _open(_adminUrl),
          ),
          _AdminTile(
            icon: Icons.play_circle_outline,
            title: 'Public Player',
            subtitle: 'Web üzerinden yayını dinle',
            onTap: () => _open(_publicPlayerUrl),
          ),
          _AdminTile(
            icon: Icons.queue_music,
            title: 'Playlist Yönetimi',
            subtitle: 'Stations → RockFMTurkey → Playlists',
            onTap: () => _open('$_adminUrl/station/1/playlists'),
          ),
          _AdminTile(
            icon: Icons.bar_chart,
            title: 'Dinleyici İstatistikleri',
            subtitle: 'Stations → Reports → Listeners',
            onTap: () => _open('$_adminUrl/station/1/reports/listeners'),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'NOT: Mobil yönetim ekranı sonraki sürümde gelecek. Şimdilik AzuraCast web paneli üzerinden yönetim yapılıyor.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold, width: 1),
      ),
      child: Row(
        children: const [
          Icon(Icons.radio, color: AppColors.gold, size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YAYIN AKTİF',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'rockfmturkey.com · 7/24 Live',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.open_in_new,
            color: AppColors.gold, size: 18),
        onTap: onTap,
      ),
    );
  }
}

Future<void> showAdminPasswordDialog(
  BuildContext context,
  bool Function(String) verify,
) async {
  final controller = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) {
      String? error;
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.gold),
          ),
          title: const Text(
            'ADMIN GİRİŞİ',
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: AppColors.gold,
                decoration: InputDecoration(
                  hintText: 'Şifre',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  errorText: error,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gold),
                  ),
                ),
                onSubmitted: (v) {
                  if (verify(v)) {
                    Navigator.of(ctx).pop(true);
                  } else {
                    setState(() => error = 'Hatalı şifre');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('İPTAL',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (verify(controller.text)) {
                  Navigator.of(ctx).pop(true);
                } else {
                  setState(() => error = 'Hatalı şifre');
                }
              },
              child: const Text('GİRİŞ',
                  style: TextStyle(color: AppColors.gold)),
            ),
          ],
        );
      });
    },
  );

  if (result == true && context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminScreen()),
    );
  }
}
