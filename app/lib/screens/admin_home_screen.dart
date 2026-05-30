import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/admin_service.dart';
import '../services/azuracast_api.dart';
import '../theme/app_theme.dart';
import 'admin_login_screen.dart';
import 'admin_library_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final String welcomeName;
  const AdminHomeScreen({super.key, required this.welcomeName});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  AzuraCastApi get _api => AzuraCastApi(context.read<AdminService>().apiKey!);

  Map<String, dynamic>? _nowPlaying;
  List<Map<String, dynamic>> _queue = [];
  int _listenerCount = 0;
  bool _loading = true;
  String? _error;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.nowPlaying(),
        _api.queue(),
      ]);
      final np = results[0] as Map<String, dynamic>;
      final q = results[1] as List<Map<String, dynamic>>;
      setState(() {
        _nowPlaying = np;
        _queue = q;
        _listenerCount = (np['listeners']?['current'] ?? 0) as int;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await context.read<AdminService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (_) => false,
    );
  }

  Future<void> _skipCurrent() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.gold),
        ),
        title: const Text('Yayını Atla?',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900)),
        content: const Text(
          'Şu an çalan şarkı kesilip kuyruktaki bir sonrakine geçilecek.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İPTAL',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ATLA', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      await _api.skipCurrentSong();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.surface,
        content: const Text('Yayın bir sonraki şarkıya atlandı',
            style: TextStyle(color: AppColors.gold)),
      ));
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.red[900],
        content: Text('Atlama hatası: $e',
            style: const TextStyle(color: Colors.white)),
      ));
    }
  }

  Future<void> _pickAndUpload() async {
    final messenger = ScaffoldMessenger.of(context);
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'm4a', 'flac', 'ogg', 'wav'],
        allowMultiple: false,
        withData: false,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.red[900],
        content: Text('Dosya seçici açılamadı: $e',
            style: const TextStyle(color: Colors.white)),
      ));
      return;
    }
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final path = file.path;
    if (path == null) {
      messenger.showSnackBar(const SnackBar(
        backgroundColor: Color(0xFF7F1010),
        content: Text('Dosya yolu okunamadı (iCloud Drive sandbox?)',
            style: TextStyle(color: Colors.white)),
      ));
      return;
    }

    final filename = file.name;
    setState(() => _uploadProgress = 0.0);
    try {
      await _api.uploadFile(
        filename: filename,
        file: File(path),
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('$filename yüklendi',
            style: const TextStyle(color: AppColors.gold)),
      ));
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.red[900],
        content: Text('Yükleme hatası: ${e.toString().substring(0, e.toString().length.clamp(0, 200))}',
            style: const TextStyle(color: Colors.white)),
      ));
    } finally {
      if (mounted) setState(() => _uploadProgress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: const Text(
          'ADMİN PANELİ',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Çıkış',
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.gold),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _WelcomeCard(name: widget.welcomeName, listeners: _listenerCount),
            const SizedBox(height: 16),
            _SectionHeader(title: 'ŞİMDİ ÇALIYOR', onAction: _refresh, actionIcon: Icons.refresh),
            const SizedBox(height: 8),
            if (_loading)
              const _LoaderCard()
            else if (_error != null)
              _ErrorCard(message: _error!)
            else
              _NowPlayingCard(data: _nowPlaying),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'KUYRUK (${_queue.length})',
              onAction: _refresh,
              actionIcon: Icons.refresh,
            ),
            const SizedBox(height: 8),
            if (!_loading && _queue.isEmpty)
              const _EmptyCard(message: 'Kuyruk boş — otomatik playlist çalıyor'),
            ..._queue.map((q) => _QueueTile(item: q, onRemove: (id) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _api.removeFromQueue(id);
                    if (!mounted) return;
                    await _refresh();
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(
                      content: Text('Silinemedi: $e'),
                    ));
                  }
                })),
            const SizedBox(height: 24),
            _SectionHeader(title: 'YÖNETİM', onAction: null, actionIcon: null),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.upload_file,
              title: 'Şarkı Yükle',
              subtitle: 'mp3 dosyası seç ve kütüphaneye ekle',
              onTap: _uploadProgress != null ? null : _pickAndUpload,
              trailing: _uploadProgress != null
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(AppColors.gold)))
                  : null,
            ),
            _ActionTile(
              icon: Icons.skip_next,
              title: 'Yayını Atla',
              subtitle: 'Şu an çalan şarkıyı bitir, sonrakine geç',
              onTap: _skipCurrent,
            ),
            _ActionTile(
              icon: Icons.library_music,
              title: 'Müzik Kütüphanesi',
              subtitle: 'Kayıtlı şarkıları listele, ara, sil, kuyruğa ekle',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminLibraryScreen()),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  final int listeners;
  const _WelcomeCard({required this.name, required this.listeners});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1305), Color(0xFF0A0A0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.gold, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio, color: AppColors.gold, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldin, $name',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'rockfmturkey.com · 7/24 yayın',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$listeners',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  )),
              const Text('DİNLEYİCİ',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  const _SectionHeader({required this.title, this.onAction, this.actionIcon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ),
        if (onAction != null && actionIcon != null)
          IconButton(
            icon: Icon(actionIcon, color: AppColors.gold, size: 18),
            onPressed: onAction,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  const _NowPlayingCard({this.data});
  @override
  Widget build(BuildContext context) {
    final np = data?['now_playing'] as Map<String, dynamic>?;
    final song = np?['song'] as Map<String, dynamic>?;
    final title = song?['title'] ?? '—';
    final artist = song?['artist'] ?? '';
    final art = song?['art'] as String?;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: art != null && art.isNotEmpty
                ? Image.network(art, width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _ArtFallback())
                : const _ArtFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    )),
                Text(artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback();
  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        color: AppColors.background,
        child: const Icon(Icons.music_note, color: AppColors.gold, size: 24),
      );
}

class _QueueTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final Future<void> Function(int)? onRemove;
  const _QueueTile({required this.item, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final song = item['song'] as Map<String, dynamic>?;
    final title = song?['title'] ?? item['title'] ?? '—';
    final artist = song?['artist'] ?? item['artist'] ?? '';
    final id = item['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.queue_music, color: AppColors.gold, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
                if (artist.toString().isNotEmpty)
                  Text(artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (id is int && onRemove != null)
            IconButton(
              tooltip: 'Kuyruktan çıkar',
              icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
              onPressed: () => onRemove!(id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: disabled ? AppColors.border : AppColors.gold),
        title: Text(title,
            style: TextStyle(
              color: disabled ? AppColors.border : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            )),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: trailing ??
            const Icon(Icons.chevron_right, color: AppColors.gold, size: 20),
        onTap: onTap,
      ),
    );
  }
}

class _LoaderCard extends StatelessWidget {
  const _LoaderCard();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.gold),
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red[900]?.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red[700]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      );
}
