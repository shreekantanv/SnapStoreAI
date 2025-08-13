import 'package:flutter/material.dart';

class DynamicResultWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const DynamicResultWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    data.forEach((key, value) {
      switch (key) {
        case 'summary':
          widgets.add(_SummaryWidget(summary: value as String));
          break;
        case 'leaning':
          widgets.add(_SpectrumWidget(leaning: (value as num).toDouble()));
          break;
        case 'topicBreakdown':
          widgets.add(_TopicListWidget(topicBreakdown: value as List));
          break;
        case 'keywordClouds':
          widgets.add(_KeywordCloudWidget(keywordClouds: value as List));
          break;
      }
      widgets.add(const SizedBox(height: 16));
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: widgets,
    );
  }
}

class _TopicListWidget extends StatelessWidget {
  final List<dynamic> topicBreakdown;
  const _TopicListWidget({required this.topicBreakdown});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Topic Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...topicBreakdown.map((topic) {
              return ListTile(
                title: Text(topic['topic'] as String),
                subtitle: Text(topic['tag'] as String),
                trailing: Text((topic['score'] as num).toStringAsFixed(2)),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _KeywordCloudWidget extends StatelessWidget {
  final List<dynamic> keywordClouds;
  const _KeywordCloudWidget({required this.keywordClouds});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keyword Clouds', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: keywordClouds.map((cloud) {
                return Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: (cloud as List).map((word) {
                      return Chip(label: Text(word as String));
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryWidget extends StatelessWidget {
  final String summary;
  const _SummaryWidget({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(summary),
          ],
        ),
      ),
    );
  }
}

class _SpectrumWidget extends StatelessWidget {
  final double leaning;
  const _SpectrumWidget({required this.leaning});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Political Spectrum', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // This is a simplified version of the SpectrumBar from the original screen
            LinearProgressIndicator(
              value: leaning,
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Left'),
                Text('Center'),
                Text('Right'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
