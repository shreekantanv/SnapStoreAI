import 'package:flutter/material.dart';

import 'package:client/models/tool.dart';
import 'package:client/widgets/dynamic_input_widget.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tool.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Image.asset(widget.tool.imageUrl, width: 64, height: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.tool.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(widget.tool.subtitle,
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            if (widget.tool.description != null) ...[
              Text(widget.tool.description!,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
            ],

            // Input Fields
            Text('Input Fields',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            // Input Fields
            ...widget.tool.inputFields.map((field) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DynamicInputWidget(
                  field: field,
                  onChanged: (value) {
                    setState(() {
                      _inputValues[field.id] = value;
                    });
                  },
                ),
              );
            }),

            const SizedBox(height: 24),

            // Generate Button
            ElevatedButton(
              onPressed: () {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Generate button pressed with inputs: $_inputValues'),
                  ),
                );
              },
              child: const Text('Generate'),
            ),

            const SizedBox(height: 24),

            // Privacy Note
            if (widget.tool.privacyNote != null)
              Text(
                widget.tool.privacyNote!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
