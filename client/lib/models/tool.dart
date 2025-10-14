import 'feature_pill.dart';
import 'how_it_works_step.dart';
import 'ai_provider.dart';

enum ToolRuntime { imageStylization, storybookGenerator }

extension ToolRuntimeInfo on ToolRuntime {
  String get id => switch (this) {
        ToolRuntime.imageStylization => 'image_stylization',
        ToolRuntime.storybookGenerator => 'storybook_generator',
      };

  static ToolRuntime fromId(String? value) {
    if (value == null || value.isEmpty) {
      return ToolRuntime.imageStylization;
    }

    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'storybook':
      case 'storybook_generator':
      case 'gemini_storybook':
        return ToolRuntime.storybookGenerator;
      case 'image':
      case 'image_edit':
      case 'image_stylizer':
      case 'image_stylization':
      default:
        return ToolRuntime.imageStylization;
    }
  }
}

class InputField {
  final String id;
  final String type;
  final String label;
  final String hint;
  final InputFieldUiConfig? ui;

  InputField({
    required this.id,
    required this.type,
    required this.label,
    required this.hint,
    this.ui,
  });

  factory InputField.fromJson(Map<String, dynamic> json) {
    final uiJson = json['ui'];
    return InputField(
      id: json['id'] as String,
      type: json['type'] as String,
      label: json['label'] as String,
      hint: json['hint'] as String,
      ui: uiJson is Map<String, dynamic>
          ? InputFieldUiConfig.fromJson(uiJson)
          : null,
    );
  }
}

class InputFieldUiConfig {
  final String? variant;
  final String? groupId;
  final String? groupLabel;
  final String? groupItemId;
  final String? groupItemLabel;
  final Map<String, dynamic> options;

  const InputFieldUiConfig({
    this.variant,
    this.groupId,
    this.groupLabel,
    this.groupItemId,
    this.groupItemLabel,
    this.options = const {},
  });

  factory InputFieldUiConfig.fromJson(Map<String, dynamic> json) {
    String? _string(dynamic value) {
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
      return null;
    }

    Map<String, dynamic> _readOptions(dynamic value) {
      if (value is Map<String, dynamic>) {
        return Map<String, dynamic>.unmodifiable(value);
      }
      return const {};
    }

    return InputFieldUiConfig(
      variant: _string(json['variant']) ?? _string(json['type']),
      groupId:
          _string(json['group']) ?? _string(json['groupId']) ?? _string(json['section']),
      groupLabel:
          _string(json['groupLabel']) ?? _string(json['sectionLabel']),
      groupItemId:
          _string(json['groupItem']) ?? _string(json['item']) ?? _string(json['page']),
      groupItemLabel: _string(json['groupItemLabel']) ?? _string(json['itemLabel'])
          ?? _string(json['pageLabel']),
      options: _readOptions(json['options']),
    );
  }
}

class Tool {
  final String id;
  final String title;
  final String subtitle;
  final String? description;
  final String imageUrl;
  final List<String> categories;
  final List<String> tags;
  final String? prompt;
  final int creditCost;
  final String? privacyNote;
  final List<InputField> inputFields;
  final List<HowItWorksStep> howItWorks;
  final List<FeaturePill> featurePills;
  final List<String> suggestedTools;
  final AiProvider? aiProvider;
  final ToolRuntime runtime;

  Tool({
    required this.id,
    required this.title,
    required this.subtitle,
    this.description,
    required this.imageUrl,
    this.categories = const [],
    this.tags = const [],
    this.prompt,
    required this.creditCost,
    this.privacyNote,
    required this.inputFields,
    this.howItWorks = const [],
    this.featurePills = const [],
    this.suggestedTools = const [],
    this.aiProvider,
    this.runtime = ToolRuntime.imageStylization,
  });

  factory Tool.fromJson(Map<String, dynamic> json, String id) {
    return Tool(
      id: id,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String,
      categories: _parseCategories(json),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => (e as String).trim())
              .where((element) => element.isNotEmpty)
              .toList(growable: false) ??
          const [],
      prompt: json['prompt'] as String?,
      creditCost: json['creditCost'] as int? ?? 1,
      privacyNote: json['privacyNote'] as String?,
      inputFields: (json['inputFields'] as List<dynamic>?)
              ?.map((e) => InputField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      howItWorks: (json['howItWorks'] as List<dynamic>?)
              ?.map((e) => HowItWorksStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      featurePills: (json['featurePills'] as List<dynamic>?)
              ?.map((e) => FeaturePill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestedTools: (json['suggestedTools'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      aiProvider: AiProviderInfo.fromId(json['aiProvider'] as String?),
      runtime: ToolRuntimeInfo.fromId(json['runtime'] as String?),
    );
  }
}

List<String> _parseCategories(Map<String, dynamic> json) {
  final categories = (json['categories'] as List<dynamic>?)
          ?.map((e) => (e as String).trim())
          .where((element) => element.isNotEmpty)
          .toList(growable: false) ??
      const [];

  if (categories.isNotEmpty) {
    return categories;
  }

  final legacyCategory = (json['category'] as String?)?.trim();
  if (legacyCategory != null && legacyCategory.isNotEmpty) {
    return [legacyCategory];
  }

  return const [];
}
