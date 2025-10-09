import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/ai_provider.dart';
import '../providers/api_key_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Map<AiProvider, TextEditingController> _controllers = {
    for (final provider in AiProvider.values) provider: TextEditingController(),
  };

  bool _hasSyncedControllers = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(ApiKeyProvider apiKeyProvider) {
    if (_hasSyncedControllers || apiKeyProvider.isLoading) {
      return;
    }

    for (final entry in _controllers.entries) {
      final stored = apiKeyProvider.keyFor(entry.key) ?? '';
      if (entry.value.text != stored) {
        entry.value.text = stored;
      }
    }
    _hasSyncedControllers = true;
  }

  Future<void> _saveKeys() async {
    final apiKeyProvider = context.read<ApiKeyProvider>();
    for (final entry in _controllers.entries) {
      await apiKeyProvider.updateKey(entry.key, entry.value.text);
    }

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
    final apiKeyProvider = context.watch<ApiKeyProvider>();
    _syncControllers(apiKeyProvider);

    final providerConfigs = [
      (
        AiProvider.gemini,
        l10n.settingsGeminiLabel,
        l10n.settingsGeminiHint,
        Icons.auto_awesome,
      ),
      (
        AiProvider.chatgpt,
        l10n.settingsChatgptLabel,
        l10n.settingsChatgptHint,
        Icons.chat_bubble_outline,
      ),
      (
        AiProvider.grok,
        l10n.settingsGrokLabel,
        l10n.settingsGrokHint,
        Icons.lock_outline,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradients?.scaffoldGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.settings),
          centerTitle: true,
        ),
        body: SafeArea(
          child: apiKeyProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
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
                                  child: Icon(Icons.key, color: cs.primary),
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
                            for (final config in providerConfigs) ...[
                              Text(
                                config.$2,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _controllers[config.$1],
                                decoration: InputDecoration(
                                  hintText: config.$3,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            FilledButton.icon(
                              onPressed: _saveKeys,
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
