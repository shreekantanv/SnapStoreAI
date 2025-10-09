import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/tool.dart';
import '../theme/app_theme.dart';

class ToolCard extends StatefulWidget {
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
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final gradients = Theme.of(context).extension<PremiumGradients>();

    final providerText = _providerLabel(widget.tool);

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          // Outer glow ring for premium look
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.18),
              blurRadius: 26,
              spreadRadius: 0,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
          gradient: gradients?.cardGradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surface.withOpacity(0.88),
                  cs.surfaceVariant.withOpacity(0.78),
                ],
              ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Glass blur layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: const SizedBox.shrink(),
              ),
            ),
            // Soft inner border (premium edge)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                onHighlightChanged: (h) => setState(() => _pressed = h),
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // VISUAL BANNER
                      SizedBox(
                        height: 118,
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
                                        cs.primary.withOpacity(0.25),
                                        cs.secondary.withOpacity(0.22),
                                      ],
                                    ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Center(
                                  child: Image.asset(
                                    widget.tool.imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 40,
                                      color: cs.onSurface.withOpacity(0.55),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Sheen overlay for a luxe finish
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.06),
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.03),
                                      ],
                                      stops: const [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.onFavoriteToggle != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: _GlassIconButton(
                                  radius: 14,
                                  icon: widget.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: widget.isFavorite
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                  onPressed: widget.onFavoriteToggle!,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // TITLE (up to 2 lines — full name visible)
                      Text(
                        widget.tool.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // SUBTITLE (1 line concise)
                      Text(
                        widget.tool.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),

                      const Spacer(),

                      // FOOTER: Provider + Tag pill(s)
                      Row(
                        children: [
                          if (providerText != null)
                            _GradientPill(
                              label: providerText,
                              icon: Icons.memory,
                            ),
                          if (providerText != null && widget.tool.tags.isNotEmpty)
                            const SizedBox(width: 8),
                          if (widget.tool.tags.isNotEmpty)
                            _SoftPill(label: widget.tool.tags.first),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _providerLabel(Tool tool) {
    final p = tool.aiProvider;
    if (p == null) return null;

    try {
      // ignore: avoid_dynamic_calls
      final displayName = (p as dynamic).displayName;
      if (displayName is String && displayName.trim().isNotEmpty) return displayName;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final name = (p as dynamic).name;
      if (name is String && name.trim().isNotEmpty) return name;
    } catch (_) {}
    try {
      // ignore: avoid_dynamic_calls
      final id = (p as dynamic).id;
      if (id is String && id.trim().isNotEmpty) return id.toUpperCase();
    } catch (_) {}

    final raw = p.toString();
    final cleaned = raw.split('.').last.replaceAll(RegExp(r'[^A-Za-z0-9+._-]'), '');
    return cleaned.isEmpty ? 'AI' : cleaned;
  }
}

class _GlassIconButton extends StatelessWidget {
  final double radius;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.radius,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
        iconSize: 18,
        icon: Icon(icon, color: color),
      ),
    );
  }
}

class _GradientPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _GradientPill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.85),
            cs.secondary.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: Colors.white,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final String label;
  const _SoftPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: tt.labelSmall?.copyWith(
          color: cs.onSurface,
          height: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
