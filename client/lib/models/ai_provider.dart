enum AiProvider { gemini, chatgpt, grok }

extension AiProviderInfo on AiProvider {
  String get id => switch (this) {
        AiProvider.gemini => 'gemini',
        AiProvider.chatgpt => 'chatgpt',
        AiProvider.grok => 'grok',
      };

  String get displayName => switch (this) {
        AiProvider.gemini => 'Gemini',
        AiProvider.chatgpt => 'ChatGPT',
        AiProvider.grok => 'Grok',
      };

  static AiProvider? fromId(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'gemini':
      case 'google_gemini':
      case 'google':
        return AiProvider.gemini;
      case 'chatgpt':
      case 'openai':
      case 'gpt':
        return AiProvider.chatgpt;
      case 'grok':
        return AiProvider.grok;
      default:
        return null;
    }
  }
}
