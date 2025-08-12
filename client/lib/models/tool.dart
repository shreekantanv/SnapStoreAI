class InputField {
  final String id;
  final String type;
  final String label;
  final String hint;

  InputField({
    required this.id,
    required this.type,
    required this.label,
    required this.hint,
  });

  factory InputField.fromJson(Map<String, dynamic> json) {
    return InputField(
      id: json['id'] as String,
      type: json['type'] as String,
      label: json['label'] as String,
      hint: json['hint'] as String,
    );
  }
}

import 'package:client/models/how_it_works_step.dart';
import 'package:client/models/feature_pill.dart';

class Tool {
  final String id;
  final String title;
  final String subtitle;
  final String? description;
  final String imageUrl;
  final String category;
  final String? prompt;
  final int creditCost;
  final String? privacyNote;
  final List<InputField> inputFields;
  final List<HowItWorksStep> howItWorks;
  final List<FeaturePill> featurePills;

  Tool({
    required this.id,
    required this.title,
    required this.subtitle,
    this.description,
    required this.imageUrl,
    required this.category,
    this.prompt,
    required this.creditCost,
    this.privacyNote,
    required this.inputFields,
    this.howItWorks = const [],
    this.featurePills = const [],
  });

  factory Tool.fromJson(Map<String, dynamic> json, String id) {
    return Tool(
      id: id,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
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
    );
  }
}
