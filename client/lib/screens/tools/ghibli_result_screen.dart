import 'dart:typed_data';

import 'package:client/l10n/app_localizations.dart';
import 'package:client/models/tool.dart';
import 'package:flutter/material.dart';

class GhibliResultScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final Tool tool;

  const GhibliResultScreen({super.key, required this.imageBytes, required this.tool});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ghibliResultTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tool.title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: InteractiveViewer(
                      minScale: 0.9,
                      maxScale: 4,
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.ghibliResultSaveHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text(MaterialLocalizations.of(context).backButtonTooltip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
