class HowItWorksStep {
  final String title;
  final String description;
  final String imageUrl;

  HowItWorksStep({
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  factory HowItWorksStep.fromJson(Map<String, dynamic> json) {
    return HowItWorksStep(
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }
}
