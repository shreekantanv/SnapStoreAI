// lib/tools/tool_entry_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:client/models/tool.dart';
import 'package:client/models/topic_tag.dart';

class ToolEntryScreen extends StatefulWidget {
  final Tool tool;
  const ToolEntryScreen({super.key, required this.tool});

  @override
  State<ToolEntryScreen> createState() => _ToolEntryScreenState();
}

class _ToolEntryScreenState extends State<ToolEntryScreen> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var field in widget.tool.inputFields)
        field.id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tool.title),
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
                      Text(widget.tool.description ?? '', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 24),
                      ...widget.tool.inputFields.map((field) {
                        return TextField(
                          controller: _controllers[field.id],
                          decoration: InputDecoration(
                            hintText: field.hint,
                            labelText: field.label,
                            border: const OutlineInputBorder(),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
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
                            final inputs = {
                              for (var field in widget.tool.inputFields)
                                field.id: _controllers[field.id]!.text,
                            };
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AnalysisInProgressScreen(tool: widget.tool, inputs: inputs),
                            ));
                          },
                          child: Text('Analyze now (${widget.tool.creditCost} credits)'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.tool.privacyNote != null)
                        Text(
                          widget.tool.privacyNote!,
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
}

/* ------------------------------ Analysis In Progress ------------------------------ */

class AnalysisInProgressScreen extends StatefulWidget {
  final Tool tool;
  final Map<String, dynamic> inputs;
  const AnalysisInProgressScreen({super.key, required this.tool, required this.inputs});

  @override
  State<AnalysisInProgressScreen> createState() => _AnalysisInProgressScreenState();
}

class _AnalysisInProgressScreenState extends State<AnalysisInProgressScreen> {
  String _status = '';

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    // This is a simplified version of the previous _runAnalysis method
    // It does not include the client-side API call logic for brevity
    setState(() => _status = 'Analyzing...');
    try {
      final apiService = context.read<ApiService>();
      final prompt = _buildPrompt();
      final response = await apiService.runTool(
        widget.tool.id,
        'grok-1', // model should probably also be part of the tool data
        prompt,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ResultsScreen(data: response['result']),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  String _buildPrompt() {
    String prompt = widget.tool.prompt ?? '';
    widget.inputs.forEach((key, value) {
      prompt = prompt.replaceAll('{{$key}}', value.toString());
    });
    return prompt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analyzing...'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
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
