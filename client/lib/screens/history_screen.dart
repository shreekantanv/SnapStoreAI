import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:client/providers/history_provider.dart';
import 'package:client/screens/tools/political_leaning_analyzer.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Builder(
        builder: (context) {
          if (historyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (historyProvider.error != null) {
            return Center(child: Text('Error: ${historyProvider.error}'));
          }
          if (historyProvider.activities.isEmpty) {
            return const Center(child: Text('No activity yet.'));
          }

          return ListView.builder(
            itemCount: historyProvider.activities.length,
            itemBuilder: (context, index) {
              final activity = historyProvider.activities[index].data() as Map<String, dynamic>;
              return _HistoryListItem(activity: activity);
            },
          );
        },
      ),
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _HistoryListItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final toolId = activity['toolId'] as String;

    switch (toolId) {
      case 'political_leaning_analyzer':
        return _buildPoliticalLeaningTile(context);
      default:
        return ListTile(
          title: Text(toolId),
          subtitle: const Text('Unknown tool type'),
        );
    }
  }

  Widget _buildPoliticalLeaningTile(BuildContext context) {
    final inputs = activity['inputs'] as Map<String, dynamic>;
    final outputs = activity['outputs'] as Map<String, dynamic>;
    final handle = inputs['value'] as String;
    final summary = outputs['summary'] as String;
    final ts = (activity['ts'] as Timestamp).toDate();

    return ListTile(
      leading: const Icon(Icons.balance),
      title: Text('Political Leaning: $handle'),
      subtitle: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text('${ts.month}/${ts.day}/${ts.year}'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PoliticalLeaningEntryScreen(
              initialActivity: activity,
            ),
          ),
        );
      },
    );
  }
}
