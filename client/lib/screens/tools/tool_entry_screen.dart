import 'dart:ui';
import 'package:client/screens/tools/tool_result_screen.dart';
import 'package:flutter/material.dart';

import 'package:client/models/tool.dart';
import 'package:client/utils/icon_mapper.dart';
import 'package:client/widgets/dynamic_input_widget.dart';
import 'package:client/widgets/feature_pill_widget.dart';
import 'package:client/widgets/how_it_works_carousel.dart';

import 'package:provider/provider.dart';

import '../../models/analysis_result.dart';
import '../../services/api_service.dart';

class ToolEntryScreen extends StatefulWidget {
  static const routeName = '/tool-entry';
  final Tool tool;
  const ToolEntryScreen({super.key, required this.tool});

  @override
  State<ToolEntryScreen> createState() => _ToolEntryScreenState();
}

class _ToolEntryScreenState extends State<ToolEntryScreen> {
  final _inputValues = <String, String>{};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final int? credits = (widget.tool as dynamic?)?.creditCost; // optional

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Premium Header ---
                  _GlassHeader(
                    imageUrl: widget.tool.imageUrl,
                    title: widget.tool.title,
                    subtitle: widget.tool.subtitle,
                  ),
                  const SizedBox(height: 16),

                  // --- Feature Pills (now includes Credits pill) ---
                  if (widget.tool.featurePills.isNotEmpty || credits != null) ...[
                    _SectionCard(
                      title: 'Highlights',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (credits != null)
                            FeaturePillWidget(
                              label: '$credits Credits',
                              icon: Icons.stars_rounded,
                            ),
                          ...widget.tool.featurePills.map((pill) {
                            return FeaturePillWidget(
                              label: pill.label,
                              icon: IconMapper.getIcon(pill.icon),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Description (optional) ---
                  if (widget.tool.description != null &&
                      widget.tool.description!.trim().isNotEmpty) ...[
                    _SectionCard(
                      title: 'About',
                      child: Text(
                        widget.tool.description!,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.85),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- How it works (optional) ---
                  if (widget.tool.howItWorks.isNotEmpty) ...[
                    _SectionCard(
                      title: 'How it works',
                      child: HowItWorksCarousel(steps: widget.tool.howItWorks),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Input Fields ---
                  _SectionCard(
                    title: 'Input Fields',
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

                  // --- Generate button (shows credits if available) ---
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      icon: _isLoading ? null : const Icon(Icons.auto_awesome_rounded),
                      label: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : Text(
                              credits == null
                                  ? 'Generate'
                                  : 'Generate • $credits Credits',
                            ),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        textStyle:
                        tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : () async {
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          final apiService = context.read<ApiService>();
                          final prompt = _inputValues.values.join(' ');
                          final resultData = await apiService.runTool(widget.tool.id, 'grok-1', prompt);
                          final analysisResult = AnalysisResult.fromJson(resultData['result']);

                          if (mounted) {
                             Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ResultsScreen(
                                  result: analysisResult,
                                  tool: widget.tool,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('An error occurred: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- Privacy Note (optional) ---
                  if (widget.tool.privacyNote != null)
                    Text(
                      widget.tool.privacyNote!,
                      textAlign: TextAlign.center,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurface.withOpacity(0.65)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ======================= Premium UI helpers ======================= */

class _GlassHeader extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;

  const _GlassHeader({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned(right: -28, top: -28, child: _Blob(color: cs.primary, size: 170, opacity: 0.18)),
          Positioned(left: -34, bottom: -34, child: _Blob(color: cs.secondary, size: 190, opacity: 0.14)),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.35),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cs.outline.withOpacity(0.10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 14),
                  ),
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
                        Text(title,
                            style: tt.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: tt.titleSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.75),
                            fontWeight: FontWeight.w600,
                          ),
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

class _CreditsChip extends StatelessWidget {
  final int credits;
  const _CreditsChip({required this.credits});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.40),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: 16, color: cs.onSurface.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(
            '$credits Credits',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: cs.surfaceVariant.withOpacity(0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
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
            BoxShadow(
              color: color.withOpacity(opacity),
              blurRadius: size / 1.7,
              spreadRadius: size / 6,
            ),
          ],
        ),
      ),
    );
  }
}
