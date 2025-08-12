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
    );
  }
}
