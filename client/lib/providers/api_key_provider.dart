import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/ai_provider.dart';

extension _AiProviderStorage on AiProvider {
  String get storageKey => switch (this) {
        AiProvider.gemini => 'gemini_api_key',
        AiProvider.chatgpt => 'chatgpt_api_key',
        AiProvider.grok => 'grok_api_key',
      };
}

class ApiKeyProvider extends ChangeNotifier {
  ApiKeyProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _loadKeys();
  }

  final FlutterSecureStorage _storage;
  final Map<AiProvider, String?> _keys = <AiProvider, String?>{
    for (final provider in AiProvider.values) provider: null,
  };

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? keyFor(AiProvider provider) => _keys[provider];

  Future<void> _loadKeys() async {
    try {
      for (final provider in AiProvider.values) {
        final key = await _storage.read(key: provider.storageKey);
        _keys[provider] = key;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateKey(AiProvider provider, String? value) async {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await _storage.delete(key: provider.storageKey);
      _keys[provider] = null;
    } else {
      await _storage.write(key: provider.storageKey, value: trimmed);
      _keys[provider] = trimmed;
    }
    notifyListeners();
  }
}
