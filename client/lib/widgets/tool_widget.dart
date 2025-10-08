import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/tool.dart';

class ToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  const ToolCard({
    required this.tool,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: radius,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            tool.subtitle,
                            maxLines: 3,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (tool.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: tool.tags.take(3).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tag,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onFavoriteToggle != null)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                tooltip: isFavorite
                    ? (l10n?.removeFromFavorites ?? 'Remove from favorites')
                    : (l10n?.addToFavorites ?? 'Add to favorites'),
                onPressed: onFavoriteToggle,
              ),
            ),
        ],
      ),
    );
  }
}

