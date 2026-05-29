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
    final id = item['id'];
    final title = item['title'] ?? item['path'] ?? '—';
    if (id is! int) return;
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

  Future<void> _queueNow(Map<String, dynamic> item) async {
    final id = item['id'];
    final title = item['title'] ?? item['path'] ?? '—';
    if (id is! int) return;
    try {
      await _api.queueRequest(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('$title kuyruğa eklendi',
            style: const TextStyle(color: AppColors.gold)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
                                onQueue: () => _queueNow(_items[i]),
                                onDelete: () => _confirmDelete(_items[i]),
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
  final VoidCallback onQueue;
  final VoidCallback onDelete;
  const _LibraryRow({
    required this.item,
    required this.onQueue,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? item['name'] ?? item['path'] ?? '—';
    final artist = item['artist'] ?? '';
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
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kuyruğa ekle',
            icon: const Icon(Icons.playlist_add,
                color: AppColors.gold, size: 20),
            onPressed: onQueue,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
          ),
          IconButton(
            tooltip: 'Sil',
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36),
          ),
        ],
      ),
    );
  }
}
