import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/admin_service.dart';
import '../services/azuracast_api.dart';
import '../theme/app_theme.dart';
import 'admin_home_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _keyController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _keyController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'API anahtarı boş olamaz');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = AzuraCastApi(raw);
      final account = await api.verifyApiKey();
      if (!mounted) return;
      await context.read<AdminService>().setApiKey(raw);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminHomeScreen(welcomeName: account['name'] ?? account['email'] ?? 'Admin'),
        ),
      );
    } on AzuraCastException catch (e) {
      setState(() => _error = e.status == 401 || e.status == 403
          ? 'API anahtarı geçersiz'
          : 'Bağlantı hatası: ${e.status}');
    } catch (e) {
      setState(() => _error = 'Sunucuya ulaşılamadı');
    } finally {
      if (mounted) setState(() => _busy = false);
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
          'ADMİN GİRİŞİ',
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.admin_panel_settings,
                  color: AppColors.gold, size: 64),
              const SizedBox(height: 16),
              const Text(
                'RockFM Turkey · Yayın Yönetimi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hesabınıza ait API anahtarını yapıştırın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _keyController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: AppColors.gold,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'API anahtarı',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  errorText: _error,
                  prefixIcon: const Icon(Icons.vpn_key, color: AppColors.gold),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gold, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                        ),
                      )
                    : const Text('GİRİŞ'),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),
              const Text(
                'API ANAHTARI NASIL ALINIR?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Web admin paneline gir ve hesabına bağlan.\n'
                '2. Sağ üst hesap menüsünden "API Keys" sayfasını aç.\n'
                '3. "Yeni Anahtar" oluştur, anahtarı kopyala, buraya yapıştır.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://rockfmturkey.com/profile/api-keys'),
                  mode: LaunchMode.externalApplication,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Web Admin\'de Aç'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
