import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/tool.dart';
import '../theme/app_theme.dart';

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
    final radius = BorderRadius.circular(22);
    final gradients = Theme.of(context).extension<PremiumGradients>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: gradients?.cardGradient,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: gradients?.heroGlow ??
                              LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cs.primary.withOpacity(0.18),
                                  cs.secondary.withOpacity(0.18),
                                ],
                              ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Center(
                            child: Image.asset(
                              tool.imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      if (onFavoriteToggle != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: cs.surface.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withOpacity(0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? cs.primary : cs.onSurfaceVariant,
                              ),
                              tooltip: isFavorite
                                  ? (l10n?.removeFromFavorites ?? 'Remove from favorites')
                                  : (l10n?.addToFavorites ?? 'Add to favorites'),
                              onPressed: onFavoriteToggle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tool.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  tool.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (tool.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: tool.tags.take(3).map((tag) {
                      return Chip(
                        label: Text(tag),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

