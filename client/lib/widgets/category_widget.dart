import 'package:flutter/material.dart';
import '../models/tool.dart';
import 'tool_widget.dart';

class CategorySection extends StatelessWidget {
  final String categoryName;
  final List<Tool> tools;

  const CategorySection({
    required this.categoryName,
    required this.tools,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (tools.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              categoryName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tools.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (_, i) => ToolCard(tool: tools[i]),
          ),
        ],
      ),
    );
  }
}
