class Tool {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String category;

  Tool({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.category,
  });

  factory Tool.fromJson(Map<String, dynamic> json, String id) {
    return Tool(
      id: id,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
    );
  }
}
