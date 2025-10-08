import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _grokApiKeyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _grokApiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _storage.read(key: 'grok_api_key');
    if (apiKey != null) {
      _grokApiKeyCtrl.text = apiKey;
    }
  }

  Future<void> _saveApiKey() async {
    await _storage.write(key: 'grok_api_key', value: _grokApiKeyCtrl.text);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsApiKeySaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradients = Theme.of(context).extension<PremiumGradients>();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradients?.scaffoldGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.settings),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: gradients?.cardGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(Icons.lock_outline, color: cs.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              l10n.settingsPremiumControlsTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.settingsGrokLabel,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _grokApiKeyCtrl,
                        decoration: InputDecoration(
                          hintText: l10n.settingsGrokHint,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _saveApiKey,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(l10n.settingsSaveApiKey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
