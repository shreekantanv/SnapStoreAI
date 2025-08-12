// lib/tools/political_leaning_analyzer.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:client/l10n/app_localizations.dart';
import 'package:client/models/topic_tag.dart';

class PoliticalLeaningEntryScreen extends StatefulWidget {
  const PoliticalLeaningEntryScreen({super.key});

  @override
  State<PoliticalLeaningEntryScreen> createState() => _PoliticalLeaningEntryScreenState();
}

class _PoliticalLeaningEntryScreenState extends State<PoliticalLeaningEntryScreen> {
  final _handleCtrl = TextEditingController();

  @override
  void dispose() {
    _handleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.politicalLeaningAnalyzer),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      // Hero / info card (visual-only changes)
                      _GlassHero(
                        title: l10n.analyzeYourXPosts,
                        subtitle: '',
                      ),
                      const SizedBox(height: 16),
                      // Handle input (visual-only changes)
                      TextField(
                        controller: _handleCtrl,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: l10n.socialMediaHandle,
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                          filled: true,
                          fillColor: cs.surfaceVariant.withOpacity(0.22),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          enabledBorder: _roundedBorder(Theme.of(context).dividerColor.withOpacity(0.18)),
                          focusedBorder: _roundedBorder(cs.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // CTA button (keeps same onPressed behavior)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          onPressed: () {
                            final handle = _handleCtrl.text.trim().isEmpty ? '@demo' : _handleCtrl.text.trim();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AnalysisInProgressScreen(handle: handle),
                            ));
                          },
                          child: Text(
                            l10n.analyze2Credits
                                .replaceAll('(', '• ')
                                .replaceAll(')', ''),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Privacy note
                      Text(
                        l10n.weAnalyzeLocally,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                        ),
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

  OutlineInputBorder _roundedBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: 1),
  );
}

class _GlassHero extends StatelessWidget {
  final String title;
  final String subtitle;
  const _GlassHero({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          // Soft background shapes
          Positioned(right: -28, top: -28, child: _Blob(color: cs.primary, size: 160, opacity: 0.18)),
          Positioned(left: -36, bottom: -36, child: _Blob(color: cs.secondary, size: 180, opacity: 0.16)),

          // Glass overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.35),
                border: Border.all(color: cs.outline.withOpacity(0.10)),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    _IconTile(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.75)),
                          ),
                          const SizedBox(height: 14),
                          // Privacy chips
                          Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _IconTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Icon(Icons.balance_rounded, size: 52, color: cs.onSurface.withOpacity(0.9)),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

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
              color: cs.onSurface.withOpacity(0.85),
              fontWeight: FontWeight.w600,
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

/* ------------------------------ Analysis In Progress ------------------------------ */

class AnalysisInProgressScreen extends StatefulWidget {
  final String handle;
  const AnalysisInProgressScreen({super.key, required this.handle});

  @override
  State<AnalysisInProgressScreen> createState() => _AnalysisInProgressScreenState();
}

class _AnalysisInProgressScreenState extends State<AnalysisInProgressScreen> {
  double _p = 0.12;

  @override
  void initState() {
    super.initState();
    // Simulate async pipeline. Replace with your Grok/X call and navigate on completion.
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 320));
      setState(() => _p = (_p + 0.09).clamp(0, 1));
      return _p < 1.0;
    }).then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultsScreen(
          handle: widget.handle,
          leaning: 0.35, // 0=Left, 0.5=Center, 1=Right
          summary:
          'You lean center‑left with emphasis on social issues and progressive policies.',
          topicBreakdown: const [
            TopicScore('Climate Change', TopicTag.progressive, 0.72),
            TopicScore('Tax Cuts', TopicTag.conservative, 0.48),
            TopicScore('Healthcare Reform', TopicTag.progressive, 0.64),
            TopicScore('Immigration Policy', TopicTag.conservative, 0.51),
            TopicScore('Education Funding', TopicTag.progressive, 0.58),
            TopicScore('Gun Rights', TopicTag.conservative, 0.43),
            TopicScore('Social Security', TopicTag.progressive, 0.55),
            TopicScore('National Defense', TopicTag.conservative, 0.50),
          ],
          keywordClouds: const [
            ['climate', 'renewables', 'emissions', 'policy', 'paris'],
            ['tax', 'cuts', 'growth', 'jobs', 'business'],
          ],
        ),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.analysisInProgress), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(l10n.analyzingYourSocialMedia,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              l10n.thisMayTakeAMoment,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.reviewingPosts, style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: _p,
                minHeight: 10,
                backgroundColor: cs.surfaceVariant.withOpacity(0.25),
                color: cs.primary,
              ),
            ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ Results ------------------------------ */

class TopicScore {
  final String topic;
  final TopicTag tag;   // e.g., Progressive / Conservative
  final double score; // 0..1
  const TopicScore(this.topic, this.tag, this.score);
}

class ResultsScreen extends StatelessWidget {
  final String handle;
  final double leaning; // 0..1
  final String summary;
  final List<TopicScore> topicBreakdown;
  final List<List<String>> keywordClouds;

  const ResultsScreen({
    super.key,
    required this.handle,
    required this.leaning,
    required this.summary,
    required this.topicBreakdown,
    required this.keywordClouds,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.analysisResults), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _Section(
            title: l10n.politicalSpectrum,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SpectrumBar(value: leaning),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(l10n.left,  style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                    const Spacer(),
                    Text(l10n.center,style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                    const Spacer(),
                    Text(l10n.right, style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.keywordClouds,
            child: Row(
              children: [
                Expanded(child: KeywordCloud(words: keywordClouds[0])),
                const SizedBox(width: 12),
                Expanded(child: KeywordCloud(words: keywordClouds[1])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: l10n.summary,
            child: Text(summary, style: TextStyle(color: cs.onSurface.withOpacity(0.8))),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: implement share/export
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.sharingNotImplemented)),
              );
            },
            child: Text(l10n.shareResult),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PoliticalLeaningEntryScreen()),
            ),
            child: Text(l10n.analyzeAgain),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => TopicBreakdownSheet(items: topicBreakdown),
            ),
            child: Text(l10n.seeTopicBreakdown),
          ),
        ],
      ),
    );
  }
}

/* ------------------------- Topic Breakdown Sheet ------------------------- */

class TopicBreakdownSheet extends StatelessWidget {
  final List<TopicScore> items;
  const TopicBreakdownSheet({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.topics, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final t = items[i];
                  return _TopicTile(score: t.score, title: t.topic, tag: t.tag);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final double score;
  final String title;
  final TopicTag tag;
  const _TopicTile({required this.score, required this.title, required this.tag});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          _Badge(icon: _iconFor(tag)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  tag == TopicTag.progressive ? 'Progressive' : 'Conservative',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: score,
                    minHeight: 8,
                    color: cs.primary,
                    backgroundColor: cs.surfaceVariant.withOpacity(0.25),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(TopicTag tag) {
    switch (tag) {
      case TopicTag.progressive:
        return Icons.eco_rounded;
      case TopicTag.conservative:
        return Icons.shield_rounded;
    }
  }
}

/* ----------------------------- Reusable UI ----------------------------- */

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceVariant.withOpacity(0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class SpectrumBar extends StatelessWidget {
  final double value; // 0..1
  const SpectrumBar({super.key, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4FC3F7),
            cs.primary.withOpacity(0.6),
            const Color(0xFFFFAB91),
          ],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment(-1.0 + (value * 2), 0),
            child: Container(
              width: 3,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KeywordCloud extends StatelessWidget {
  final List<String> words;
  const KeywordCloud({super.key, required this.words});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [cs.surfaceVariant.withOpacity(0.35), cs.surface]),
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: words.map((w) {
              return Text(
                w.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.0 + (w.length % 6) * 2.0,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  const _Badge({required this.icon});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.25),
        border: Border.all(color: cs.outline.withOpacity(0.14)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: cs.onSurface.withOpacity(0.7)),
    );
  }
}
