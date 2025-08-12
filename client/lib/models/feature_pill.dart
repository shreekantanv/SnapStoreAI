class FeaturePill {
  final String label;
  final String icon;

  FeaturePill({
    required this.label,
    required this.icon,
  });

  factory FeaturePill.fromJson(Map<String, dynamic> json) {
    return FeaturePill(
      label: json['label'] as String,
      icon: json['icon'] as String,
    );
  }
}
