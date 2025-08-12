// lib/tools/political_leaning_analyzer.dart
import 'package:flutter/material.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Political Leaning Analyzer'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            Expanded(
              child: Card(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1C2835), Color(0xFF0E1318)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.scale_rounded, size: 84),
                      ),
                      const SizedBox(height: 16),
                      Text('Analyze your X (Twitter) posts',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      const Text(
                        'We analyze locally/securely and do not store your data.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF8DA0AE)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _handleCtrl,
              decoration: const InputDecoration(
                hintText: 'Social Media Handle (e.g., @username)',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary, foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final handle = _handleCtrl.text.trim().isEmpty ? '@demo' : _handleCtrl.text.trim();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AnalysisInProgressScreen(handle: handle),
                  ));
                },
                child: const Text('Analyze (2 Credits)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            TopicScore('Climate Change', 'Progressive', 0.72),
            TopicScore('Tax Cuts', 'Conservative', 0.48),
            TopicScore('Healthcare Reform', 'Progressive', 0.64),
            TopicScore('Immigration Policy', 'Conservative', 0.51),
            TopicScore('Education Funding', 'Progressive', 0.58),
            TopicScore('Gun Rights', 'Conservative', 0.43),
            TopicScore('Social Security', 'Progressive', 0.55),
            TopicScore('National Defense', 'Conservative', 0.50),
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis in Progress'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text('Analyzing your social media activity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text(
              'This may take a moment. Your data remains private and is not stored.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8A97A5)),
            ),
            const SizedBox(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Reviewing posts...', style: TextStyle(color: Color(0xFF9AA6B2))),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: _p,
                minHeight: 10,
                backgroundColor: const Color(0xFF1A2430),
                color: cs.primary,
              ),
            ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ Results ------------------------------ */

class TopicScore {
  final String topic;
  final String tag;   // e.g., Progressive / Conservative
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Results'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _Section(
            title: 'Political Spectrum',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SpectrumBar(value: leaning),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Text('Left',  style: TextStyle(color: Color(0xFF9AA6B2))),
                    Spacer(),
                    Text('Center',style: TextStyle(color: Color(0xFF9AA6B2))),
                    Spacer(),
                    Text('Right', style: TextStyle(color: Color(0xFF9AA6B2))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Keyword Clouds',
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
            title: 'Summary',
            child: Text(summary, style: const TextStyle(color: Color(0xFFB6C2CD))),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: implement share/export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing not implemented in demo.')),
              );
            },
            child: const Text('Share Result'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AnalysisInProgressScreen(handle: handle)),
            ),
            child: const Text('Analyze Again'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF0F151C),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => TopicBreakdownSheet(items: topicBreakdown),
            ),
            child: const Text('See Topic Breakdown'),
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
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFF253241), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Topics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
  final String tag;
  const _TopicTile({required this.score, required this.title, required this.tag});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101923),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1D2733)),
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
                Text(tag, style: const TextStyle(color: Color(0xFF7F8B97))),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: score,
                    minHeight: 8,
                    color: cs.primary,
                    backgroundColor: const Color(0xFF1B2430),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String tag) {
    switch (tag.toLowerCase()) {
      case 'progressive': return Icons.eco_rounded;
      case 'conservative': return Icons.shield_rounded;
      default: return Icons.balance_rounded;
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
    return Card(
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
    return Container(
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF9FA8DA), Color(0xFFFFAB91)],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment(-1.0 + (value * 2), 0),
            child: Container(
              width: 3, height: 22,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(2),
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
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [Color(0xFF17202A), Color(0xFF0E141B)]),
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
                  color: Colors.white.withOpacity(0.85),
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
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1822),
        border: Border.all(color: const Color(0xFF1E2A36)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: const Color(0xFF99A8B5)),
    );
  }
}
