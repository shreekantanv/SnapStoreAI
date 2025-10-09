// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get signIn => 'Sign In';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get toolStore => 'Tool Store';

  @override
  String get searchForTools => 'Search for tools';

  @override
  String get all => 'All';

  @override
  String get tools => 'Tools';

  @override
  String get favorites => 'Favorites';

  @override
  String get homeHeroGeneric => 'Welcome to SnapStoreAI';

  @override
  String homeHeroTitle(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get homeHeroSubtitle => 'Curated AI tools to elevate your workflow.';

  @override
  String get premiumHighlights => 'Premium highlights';

  @override
  String homeToolCount(int count) {
    return 'Explore $count handpicked tools.';
  }

  @override
  String get favoritesCta =>
      'Tap the heart on any tool to curate your favorites.';

  @override
  String get tags => 'Tags';

  @override
  String get clearTagFilters => 'Clear tag filters';

  @override
  String get noToolsFoundTitle => 'No tools found';

  @override
  String get noToolsFoundSubtitle =>
      'Try a different keyword, tag, or category.';

  @override
  String get noFavoritesTitle => 'No favorites yet';

  @override
  String get noFavoritesSubtitle =>
      'Tap the heart icon on a tool to save it for quick access.';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get history => 'History';

  @override
  String get historyEmptyTitle => 'No history yet';

  @override
  String get historyEmptySubtitle =>
      'Run a tool to see your recent activity here.';

  @override
  String get historyErrorMessage =>
      'We couldn\'t load your activity right now.';

  @override
  String get historyInputsLabel => 'Inputs';

  @override
  String get historyOutputsLabel => 'Results';

  @override
  String get historyUnknownTool => 'Unknown tool';

  @override
  String get historyUnknownTime => 'Unknown time';

  @override
  String get retry => 'Retry';

  @override
  String get settingsApiKeySaved => 'API key saved securely.';

  @override
  String get settingsPremiumControlsTitle => 'Premium Controls';

  @override
  String get settingsGrokLabel => 'Grok API Key';

  @override
  String get settingsGrokHint => 'Enter your Grok API key';

  @override
  String get settingsSaveApiKey => 'Save API Keys';

  @override
  String get settings => 'Settings';

  @override
  String get aiToolbox => 'AI Toolbox';

  @override
  String get politicalLeaningAnalyzer => 'Political Leaning Analyzer';

  @override
  String get analyzeYourXPosts => 'Analyze X posts';

  @override
  String get weAnalyzeLocally =>
      'We analyze locally/securely and do not store your data.';

  @override
  String get socialMediaHandle => 'Social Media Handle (e.g., @username)';

  @override
  String get analyze2Credits => 'Analyze (2 Credits)';

  @override
  String get analysisInProgress => 'Analysis in Progress';

  @override
  String get analyzingYourSocialMedia => 'Analyzing your social media activity';

  @override
  String get thisMayTakeAMoment =>
      'This may take a moment. Your data remains private and is not stored.';

  @override
  String get reviewingPosts => 'Reviewing posts...';

  @override
  String get cancel => 'Cancel';

  @override
  String get analysisResults => 'Analysis Results';

  @override
  String get politicalSpectrum => 'Political Spectrum';

  @override
  String get left => 'Left';

  @override
  String get center => 'Center';

  @override
  String get right => 'Right';

  @override
  String get keywordClouds => 'Keyword Clouds';

  @override
  String get summary => 'Summary';

  @override
  String get sharingNotImplemented => 'Sharing not implemented in demo.';

  @override
  String get shareResult => 'Share Result';

  @override
  String get analyzeAgain => 'Analyze Again';

  @override
  String get seeTopicBreakdown => 'See Topic Breakdown';

  @override
  String get topics => 'Topics';

  @override
  String get progressive => 'Progressive';

  @override
  String get conservative => 'Conservative';

  @override
  String get suggestedNextSteps => 'Suggested Next Steps';

  @override
  String get settingsGeminiLabel => 'Gemini API Key';

  @override
  String get settingsGeminiHint => 'Enter your Gemini API key';

  @override
  String get settingsChatgptLabel => 'ChatGPT API Key';

  @override
  String get settingsChatgptHint => 'Enter your ChatGPT API key';

  @override
  String get toolProviderLabel => 'AI Provider';

  @override
  String get toolProviderStatusMissing => 'API key not configured';

  @override
  String get toolProviderStatusReady => 'API key saved';

  @override
  String get toolRunButton => 'Run Tool';

  @override
  String get toolMissingProvider =>
      'This tool doesn\'t specify an AI provider yet.';

  @override
  String toolMissingApiKey(String provider) {
    return 'Add your $provider API key in Settings to run this tool.';
  }

  @override
  String toolApiKeyInUse(String provider, String suffix) {
    return 'Running with your $provider API key ending in $suffix.';
  }

  @override
  String get toolImageRequired => 'Please upload a photo to continue.';

  @override
  String get imagePickerUploadButton => 'Upload photo';

  @override
  String get imagePickerReplaceButton => 'Replace photo';

  @override
  String get imagePickerRemoveButton => 'Remove photo';

  @override
  String get toolProviderUnsupported =>
      'This provider is not supported for this tool yet.';

  @override
  String toolRunFailed(String error) {
    return 'We couldn\'t complete the tool run. $error';
  }

  @override
  String get toolImageResultSummary =>
      'Here is your stylized artwork, ready to save or share.';

  @override
  String get toolResultSingleImageRange => 'Single image';
}
