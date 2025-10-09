import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/analysis_result.dart';
import '../../widgets/icon_list.dart';
import '../../l10n/app_localizations.dart';
import '../../models/tool.dart';
import '../../providers/tool_provider.dart';
import 'package:provider/provider.dart';
import 'tool_entry_screen.dart';


/// ======================
/// Premium Results Screen
/// ======================
class ResultsScreen extends StatelessWidget {
  final AnalysisResult result;
  final Tool tool;

  const ResultsScreen({super.key, required this.result, required this.tool});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (result.status) {
        AnalysisStatus.loading => const _LoadingState(),
        AnalysisStatus.empty => const _EmptyState(),
        AnalysisStatus.error => _ErrorState(message: result.errorMessage),
        AnalysisStatus.success => _PremiumSuccess(
          result: result,
          iconListItems: _deriveTopicsFrom(context, result),
          tool: tool,
        ),
      },
    );
  }

  /// Create a clean, generic list from your existing result.
  /// - Uses Keyword groups as row titles
  /// - Uses the dominant alignment as a tag (Progressive/Centrist/Conservative)
  /// - Provides friendly icons based on topic name; falls back to Icons.topic
  static List<PremiumListItem> _deriveTopicsFrom(
      BuildContext context, AnalysisResult r) {
    final groups = r.keywords ?? const <KeywordGroup>[];
    if (groups.isEmpty) return const <PremiumListItem>[];

    // Dominant stance (e.g., Progressive/Conservative/Centrist)
    String? dominantTag;
    final aligns = r.alignments ?? const <ResultAlignment>[];
    if (aligns.isNotEmpty) {
      final sorted = [...aligns]..sort((a, b) => b.percent.compareTo(a.percent));
      dominantTag = sorted.first.label;
    }

    IconData pickIcon(String topic) {
      final t = topic.toLowerCase();
      if (t.contains('climate') || t.contains('environment')) return Icons.eco_outlined;
      if (t.contains('tax')) return Icons.attach_money;
      if (t.contains('health')) return Icons.health_and_safety_outlined;
      if (t.contains('immigration')) return Icons.groups_2_outlined;
      if (t.contains('education') || t.contains('school')) return Icons.school_outlined;
      if (t.contains('gun')) return Icons.security_outlined;
      if (t.contains('social')) return Icons.people_alt_outlined;
      if (t.contains('defense') || t.contains('security')) return Icons.shield_outlined;
      return Icons.topic;
    }

    // Use each group’s topic as title, show a subtle subtitle for context.
    return groups.take(8).map((g) {
      return PremiumListItem(
        icon: pickIcon(g.topic),
        title: g.topic,
        subtitle: 'Key Topic',
        tag: dominantTag, // stay generic; you can compute per-topic later if desired
        onTap: null,
      );
    }).toList(growable: false);
  }
}

/// ----------------------
/// SUCCESS (Premium UI)
/// ----------------------
class _PremiumSuccess extends StatelessWidget {
  final AnalysisResult result;
  final List<PremiumListItem> iconListItems; // ⬅️ new
  final Tool tool;

  const _PremiumSuccess({
    required this.result,
    required this.iconListItems,
    required this.tool,
  });

  @override
  Widget build(BuildContext context) {
    final nowStr = DateFormat.yMMMEd().add_jm().format(DateTime.now());
    final cs = Theme.of(context).colorScheme;
    final hasMeta = result.meta != null;
    final hasSpectrum = result.spectrum != null;
    final hasAlignments = (result.alignments?.isNotEmpty ?? false);
    final hasSummary = (result.summary?.trim().isNotEmpty ?? false);
    final hasHeroImage =
        result.subjectImageBytes != null || (result.subjectImage?.isNotEmpty ?? false);

    final content = <Widget>[];

    if (hasHeroImage) {
      content
        ..add(
          _HeroMedia(
            imageBytes: result.subjectImageBytes,
            imageUrl: result.subjectImage,
          ),
        )
        ..add(const SizedBox(height: 16));
    }

    if (hasSpectrum) {
      content
        ..add(_GlassCard(child: _SpectrumSection(spectrum: result.spectrum!)))
        ..add(const SizedBox(height: 12));
    }

    if (hasAlignments) {
      content
        ..add(_GlassCard(child: _AlignmentSection(alignments: result.alignments!)))
        ..add(const SizedBox(height: 12));
    }

    if (iconListItems.isNotEmpty) {
      content
        ..add(
          _GlassCard(
            child: PremiumIconList(
              header: 'Topics',
              items: iconListItems,
              tagAsPill: true,
              tagColor: (ctx, it) {
                final s = (it.tag ?? '').toLowerCase();
                final palette = Theme.of(ctx).colorScheme;
                if (s.startsWith('prog')) return palette.tertiary;
                if (s.startsWith('cons')) return palette.primary;
                if (s.startsWith('cent')) return palette.secondary;
                return palette.onSurface.withOpacity(0.7);
              },
              trailingBuilder: (ctx, it) => Icon(
                Icons.chevron_right,
                color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
          ),
        )
        ..add(const SizedBox(height: 12));
    }

    if (hasSummary) {
      content
        ..add(_GlassCard(child: _SummarySection(summary: result.summary!)))
        ..add(const SizedBox(height: 12));
    }

    if (tool.suggestedTools.isNotEmpty) {
      content
        ..add(_SuggestedNextSteps(tool: tool))
        ..add(const SizedBox(height: 16));
    }

    content
      ..add(
        _PrimaryActions(
          onShareImage: () => _toast(context, 'Share coming soon'),
          onExportJson: () => _toast(context, 'Export coming soon'),
          onRerun: () => Navigator.of(context).pop(),
        ),
      )
      ..add(const SizedBox(height: 20));

    if (hasMeta) {
      content
        ..add(_FooterMeta(meta: result.meta!))
        ..add(const SizedBox(height: 12));
    }

    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surfaceContainerHighest.withOpacity(0.0),
                cs.primary.withOpacity(0.08),
                cs.secondary.withOpacity(0.06),
              ],
            ),
          ),
        ),

        // Content
        CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(tool.title),
              centerTitle: false,
              actions: [
                if (hasMeta)
                  IconButton(
                    tooltip: 'Methodology & Limitations',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      useSafeArea: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _MethodologySheet(meta: result.meta!),
                    ),
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(22),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    nowStr,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: content,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ----------------------
/// Components
/// ----------------------

class _HeroMedia extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  const _HeroMedia({this.imageUrl, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget buildImage() {
      if (imageBytes != null && imageBytes!.isNotEmpty) {
        return Image.memory(
          imageBytes!,
          fit: BoxFit.cover,
        );
      }

      if (imageUrl != null && imageUrl!.isNotEmpty) {
        return Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: cs.surfaceContainerHighest.withOpacity(0.3),
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 48),
            ),
          ),
        );
      }

      return Container(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        child: const Center(
          child: Icon(Icons.image, size: 48),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: buildImage(),
          ),
          // Subtle overlay gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpectrumSection extends StatelessWidget {
  final Spectrum spectrum;
  const _SpectrumSection({required this.spectrum});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Spectrum', style: tt.titleLarge),
            const Spacer(),
            _SoftPill(
              icon: Icons.verified,
              label: 'Confidence ${spectrum.confidence.toStringAsFixed(0)}%',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Premium bar
        _GradientBar(
          value: spectrum.value / 100.0,
          leftLabel: spectrum.minLabel,
          rightLabel: spectrum.maxLabel,
        ),

        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                spectrum.minLabel,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            Text(
              '${spectrum.value}%',
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
            Expanded(
              child: Text(
                spectrum.maxLabel,
                textAlign: TextAlign.end,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlignmentSection extends StatelessWidget {
  final List<ResultAlignment> alignments;
  const _AlignmentSection({required this.alignments});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alignment', style: tt.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: alignments
              .map(
                (a) => _MetricChip(
              label: a.label,
              value: a.percent,
            ),
          )
              .toList(),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String summary;
  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary', style: tt.titleLarge),
        const SizedBox(height: 8),
        Text(
          summary,
          style: tt.bodyMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 12),
        Divider(color: cs.outlineVariant.withOpacity(0.4)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.help_outline),
            label: const Text('How to interpret these results?'),
          ),
        ),
      ],
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  final VoidCallback onShareImage;
  final VoidCallback onExportJson;
  final VoidCallback onRerun;

  const _PrimaryActions({
    required this.onShareImage,
    required this.onExportJson,
    required this.onRerun,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary CTA
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.image_outlined),
            label: const Text('Share Image'),
            onPressed: onShareImage,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export JSON'),
                onPressed: onExportJson,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Re-run'),
                onPressed: onRerun,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterMeta extends StatelessWidget {
  final Meta meta;
  const _FooterMeta({required this.meta});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Text(
      'Model: ${meta.modelUsed}  •  Items: ${meta.analyzedItemsCount}  •  Range: ${meta.timeRange}\n'
          'Disclaimer: Automated analysis; may contain bias or inaccuracies.',
      textAlign: TextAlign.center,
      style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6)),
    );
  }
}

/// ----------------------
/// Reusable “Premium” UI
/// ----------------------

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SoftPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _GradientBar extends StatelessWidget {
  final double value; // 0..1
  final String leftLabel;
  final String rightLabel;

  const _GradientBar({
    required this.value,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final knobX = (width - 20) * value; // knob diameter ~20

        return Container(
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.85),
                cs.tertiary.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Background subtle
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.25),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              // Knob
              Positioned(
                left: knobX,
                top: -4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final int value; // percent
  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(label, style: tt.labelLarge),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$value%',
              style: tt.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String text;
  const _TagPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        color: cs.surface.withOpacity(0.55),
      ),
      child: Text(text),
    );
  }
}

/// ----------------------
/// Methodology BottomSheet
/// ----------------------
class _MethodologySheet extends StatelessWidget {
  final Meta meta;
  const _MethodologySheet({required this.meta});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.8),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Methodology',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  _MethodRow(label: 'Model Used', value: meta.modelUsed),
                  _MethodRow(
                      label: 'Items Analyzed',
                      value: meta.analyzedItemsCount.toString()),
                  _MethodRow(label: 'Time Range', value: meta.timeRange),
                  const SizedBox(height: 16),
                  Text(
                    'This analysis is generated by an AI model for informational purposes only and may contain bias or errors.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurface.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
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

class _MethodRow extends StatelessWidget {
  final String label;
  final String value;
  const _MethodRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.onSurface.withOpacity(0.8)),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// ----------------------
/// States
/// ----------------------
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Subtle glass loader card
          _GlassCard(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                ),
                const SizedBox(width: 14),
                const Text('Analyzing…'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.info_outline,
      title: 'No Recent Activity',
      subtitle:
      'Not enough recent activity to generate a result. Try broadening the time range and re-run.',
      buttonText: 'Go Back',
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  const _ErrorState({this.message});

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.error_outline,
      iconColor: Colors.red,
      title: 'Something went wrong',
      subtitle: message ?? 'An unknown error occurred.',
      buttonText: 'Try Again',
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class _CenteredState extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _CenteredState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: iconColor ?? cs.primary),
              const SizedBox(height: 12),
              Text(title, style: tt.titleLarge),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(onPressed: onPressed, child: Text(buttonText)),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------
/// Helpers
/// ----------------------
void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

class _SuggestedNextSteps extends StatelessWidget {
  final Tool tool;
  const _SuggestedNextSteps({required this.tool});

  @override
  Widget build(BuildContext context) {
    final toolProvider = context.read<ToolProvider>();
    final suggestedToolIds = tool.suggestedTools;

    if (suggestedToolIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Tool>>(
      stream: toolProvider.getToolsByIds(suggestedToolIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final suggestedTools = snapshot.data!;

        final items = suggestedTools.map((tool) {
          return PremiumListItem(
            icon: Icons.auto_awesome, // Placeholder icon
            title: tool.title,
            subtitle: tool.subtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ToolEntryScreen(tool: tool),
                ),
              );
            },
          );
        }).toList();

        return _GlassCard(
          child: PremiumIconList(
            header: AppLocalizations.of(context)!.suggestedNextSteps,
            items: items,
            trailingBuilder: (ctx, it) => Icon(
              Icons.chevron_right,
              color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
        );
      },
    );
  }
}
