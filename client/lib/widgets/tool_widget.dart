import 'package:flutter/material.dart';
import '../models/tool.dart';

class ToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback? onTap;
  const ToolCard({required this.tool, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ⬇️ use one of the image blocks above here
            SizedBox(
              height: 120,
              child: Container(
                color: const Color(0xFF0F151C),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Image.asset(
                    tool.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: [
                    Text(
                      tool.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        tool.subtitle,
                        maxLines: 3, overflow: TextOverflow.fade,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

