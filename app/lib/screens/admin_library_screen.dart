import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/admin_service.dart';
import '../services/azuracast_api.dart';
import '../theme/app_theme.dart';

class AdminLibraryScreen extends StatefulWidget {
  const AdminLibraryScreen({super.key});

  @override
  State<AdminLibraryScreen> createState() => _AdminLibraryScreenState();
}

class _AdminLibraryScreenState extends State<AdminLibraryScreen> {
  AzuraCastApi get _api => AzuraCastApi(context.read<AdminService>().apiKey!);

  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.files(search: _search.text.trim());
      setState(() {
        _items = r;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final media = item['media'] is Map ? item['media'] as Map : item;
    final id = media['id'] ?? item['id'];
    final title = item['text'] ?? media['title'] ?? item['path'] ?? '—';
    if (id is! int) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red[900],
        content: const Text('Silinemiyor: kayıt ID bulunamadı',
            style: TextStyle(color: Colors.white)),
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.gold),
        ),
        title: const Text('Sil?',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900)),
        content: Text('"$title" kütüphaneden silinecek.',
            style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İPTAL',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('SİL', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      await _api.deleteFile(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('$title silindi',
            style: const TextStyle(color: AppColors.gold)),
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red[900],
        content: Text('Silinemedi: $e',
            style: const TextStyle(color: Colors.white)),
      ));
    }
  }

  Future<void> _addToBroadcast(Map<String, dynamic> item) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = item['path'];
    final title = item['text'] ?? item['path'] ?? '—';
    if (path is! String || path.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        backgroundColor: Color(0xFF7F1010),
        content: Text('Dosya yolu bulunamadı',
            style: TextStyle(color: Colors.white)),
      ));
      return;
    }
    try {
      final plId = await _api.getDefaultPlaylistId();
      if (plId == null) {
        messenger.showSnackBar(const SnackBar(
          backgroundColor: Color(0xFF7F1010),
          content: Text('Aktif playlist bulunamadı',
              style: TextStyle(color: Colors.white)),
        ));
        return;
      }
      await _api.addFilesToPlaylist([path], plId);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('$title yayına eklendi',
            style: const TextStyle(color: AppColors.gold)),
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.red[900],
        content: Text('Eklenemedi: $e',
            style: const TextStyle(color: Colors.white)),
      ));
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
          'KÜTÜPHANE',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: AppColors.textPrimary),
              cursorColor: AppColors.gold,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Ara (başlık, sanatçı...)',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.gold),
                  onPressed: _load,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.gold)),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('Hata: $_error',
                              style:
                                  const TextStyle(color: Colors.redAccent)),
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(
                            child: Text(
                              'Kayıt bulunamadı',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.gold,
                            backgroundColor: AppColors.surface,
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => _LibraryRow(
                                item: _items[i],
                                onDelete: () => _confirmDelete(_items[i]),
                                onAddToBroadcast: () => _addToBroadcast(_items[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;
  final VoidCallback onAddToBroadcast;
  const _LibraryRow({
    required this.item,
    required this.onDelete,
    required this.onAddToBroadcast,
  });
  @override
  Widget build(BuildContext context) {
    final media = item['media'] is Map ? item['media'] as Map : const {};
    final title = item['text'] ?? media['title'] ?? item['path'] ?? '—';
    final artist = media['artist'] ?? item['artist'] ?? '';
    final playlists = (media['playlists'] as List?) ?? const [];
    final inBroadcast = playlists.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.music_note, color: AppColors.gold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
                if (artist.toString().isNotEmpty)
                  Text(artist.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                _BroadcastBadge(active: inBroadcast),
              ],
            ),
          ),
          if (!inBroadcast)
            IconButton(
              tooltip: 'Yayına ekle',
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.gold, size: 22),
              onPressed: onAddToBroadcast,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40),
            ),
          IconButton(
            tooltip: 'Sil',
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 22),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40),
          ),
        ],
      ),
    );
  }
}

class _BroadcastBadge extends StatelessWidget {
  final bool active;
  const _BroadcastBadge({required this.active});
  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : Colors.redAccent;
    final label = active ? 'YAYINDA' : 'YAYIN DIŞI';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}
