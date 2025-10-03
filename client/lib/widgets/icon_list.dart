import 'package:flutter/material.dart';

/// Generic data model for a premium list row.
class PremiumListItem {
  final IconData icon;         // Leading icon
  final String title;          // Primary line
  final String? subtitle;      // Secondary line (optional)
  final String? tag;           // Small status/value/stance (optional)
  final VoidCallback? onTap;   // Row tap (optional)

  const PremiumListItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.tag,
    this.onTap,
  });
}

/// A reusable, domain-agnostic premium list widget.
class PremiumIconList extends StatelessWidget {
  final String? header;
  final List<PremiumListItem> items;
  final Color Function(BuildContext, PremiumListItem)? tagColor;
  final bool tagAsPill;
  final Widget Function(BuildContext, PremiumListItem)? trailingBuilder;

  const PremiumIconList({
    super.key,
    required this.items,
    this.header,
    this.tagColor,
    this.tagAsPill = true,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) ...[
          Text(header!, style: tt.titleLarge),
          const SizedBox(height: 12),
        ],
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _PremiumRow(
            item: items[i],
            tagColor: tagColor?.call(context, items[i]),
            tagAsPill: tagAsPill,
            trailing: trailingBuilder?.call(context, items[i]),
          ),
        ),
      ],
    );
  }
}

class _PremiumRow extends StatelessWidget {
  final PremiumListItem item;
  final Color? tagColor;
  final bool tagAsPill;
  final Widget? trailing;

  const _PremiumRow({
    required this.item,
    required this.tagColor,
    required this.tagAsPill,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final resolvedTagColor = tagColor ?? cs.onSurface.withOpacity(0.7);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cs.surface.withOpacity(0.55),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: tt.titleMedium),
                  if (item.subtitle != null || item.tag != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.subtitle != null)
                          Flexible(
                            child: Text(
                              item.subtitle!,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.75),
                              ),
                            ),
                          ),
                        if (item.subtitle != null && item.tag != null)
                          const SizedBox(width: 8),
                        if (item.tag != null)
                          tagAsPill
                              ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: resolvedTagColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.tag!,
                              style: tt.labelSmall?.copyWith(
                                color: resolvedTagColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                              : Text(
                            item.tag!,
                            style: tt.bodySmall?.copyWith(
                              color: resolvedTagColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right,
                    color: cs.onSurface.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }
}
