import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class ListScreen extends StatelessWidget {
  final String title;
  final bool favoritesOnly;
  const ListScreen({super.key, required this.title, required this.favoritesOnly});

  @override
  Widget build(BuildContext context) {
    final hist = context.watch<HistoryService>();
    final items = favoritesOnly ? hist.favorites : hist.history;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (!favoritesOnly && items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.gold),
              tooltip: 'Geçmişi temizle (favoriler kalır)',
              onPressed: () => hist.clearHistory(),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                favoritesOnly
                    ? 'Henüz favori şarkı yok.\nGeçmişten yıldıza basarak ekle.'
                    : 'Henüz çalan şarkı yok.\nYayını başlat, geçmiş otomatik birikecek.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(
                color: AppColors.border,
                height: 1,
              ),
              itemBuilder: (_, i) {
                final t = items[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: t.art != null && t.art!.isNotEmpty
                        ? Image.network(t.art!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.music_note,
                              color: AppColors.gold,
                            ))
                        : const Icon(Icons.music_note, color: AppColors.gold),
                  ),
                  title: Text(
                    t.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    t.artist,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      t.favorite ? Icons.favorite : Icons.favorite_border,
                      color: t.favorite ? AppColors.gold : AppColors.textSecondary,
                    ),
                    onPressed: () => hist.toggleFavorite(t),
                  ),
                );
              },
            ),
    );
  }
}
