import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:client/models/tool.dart';
import 'package:client/widgets/dynamic_input_widget.dart';
import 'package:client/widgets/how_it_works_carousel.dart';

class ToolEntryScreen extends StatefulWidget {
  static const routeName = '/tool-entry';
  final Tool tool;
  const ToolEntryScreen({super.key, required this.tool});

  @override
  State<ToolEntryScreen> createState() => _ToolEntryScreenState();
}

class _ToolEntryScreenState extends State<ToolEntryScreen> {
  final _inputValues = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final int credits = widget.tool.creditCost ?? 0; // <-- assumes Tool.credits

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(widget.tool.title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, c) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GlassHero(
                        imageUrl: widget.tool.imageUrl,
                        title: widget.tool.title,
                        subtitle: widget.tool.subtitle,
                        description: widget.tool.description,
                        credits: credits, // <-- show in hero
                      ),
                      const SizedBox(height: 20),

                      if (widget.tool.howItWorks.isNotEmpty) ...[
                        _SectionCard(child: HowItWorksCarousel(steps: widget.tool.howItWorks)),
                        const SizedBox(height: 16),
                      ],

                      _SectionCard(
                        child: Column(
                          children: [
                            for (final field in widget.tool.inputFields) ...[
                              DynamicInputWidget(
                                field: field,
                                onChanged: (value) {
                                  setState(() {
                                    _inputValues[field.id] = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Generate button (now shows credits)
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: Text('Generate • $credits Credits'),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Generate with $credits credits and inputs: $_inputValues')),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (widget.tool.privacyNote != null)
                        Text(
                          widget.tool.privacyNote!,
                          textAlign: TextAlign.center,
                          style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.65)),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/* -------------------------- Premium UI Bits -------------------------- */

class _GlassHero extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String? description;
  final int credits;

  const _GlassHero({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.credits,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: _Blob(color: cs.primary, size: 180, opacity: 0.18)),
          Positioned(left: -36, bottom: -36, child: _Blob(color: cs.secondary, size: 200, opacity: 0.14)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.35),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cs.outline.withOpacity(0.10)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 16)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.outline.withOpacity(0.12)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(imageUrl, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: tt.titleSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            description!,
                            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.78)),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(icon: Icons.lock_rounded, label: 'Local & Secure'),
                            _Pill(icon: Icons.visibility_off_rounded, label: 'No Data Stored'),
                            _Pill(icon: Icons.bolt_rounded, label: 'Fast'),
                            _Pill(
                              icon: Icons.stars_rounded,
                              label: '$credits Credits', // <-- credits pill
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceVariant.withOpacity(0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: child,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _Blob({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
          boxShadow: [
            BoxShadow(color: color.withOpacity(opacity), blurRadius: size / 1.7, spreadRadius: size / 6),
          ],
        ),
      ),
    );
  }
}
