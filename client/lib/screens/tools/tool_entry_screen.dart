import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:client/models/ai_provider.dart';
import 'package:client/models/analysis_result.dart';
import 'package:client/models/tool.dart';
import 'package:client/models/tool_input_value.dart';
import 'package:client/screens/tools/tool_result_screen.dart';
import 'package:client/utils/icon_mapper.dart';
import 'package:client/widgets/dynamic_input_widget.dart';
import 'package:client/widgets/feature_pill_widget.dart';
import 'package:client/widgets/how_it_works_carousel.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/api_key_provider.dart';
import '../../providers/favorite_tools_provider.dart';
import '../../providers/history_provider.dart';

class ToolEntryScreen extends StatefulWidget {
  static const routeName = '/tool-entry';
  final Tool tool;
  const ToolEntryScreen({super.key, required this.tool});

  @override
  State<ToolEntryScreen> createState() => _ToolEntryScreenState();
}

class _ToolEntryScreenState extends State<ToolEntryScreen> {
  final _inputValues = <String, ToolInputValue>{};
  late final http.Client _httpClient;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  Future<void> _runTool() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = widget.tool.aiProvider;

    if (provider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.toolMissingProvider)),
      );
      return;
    }

    final apiKeyProvider = context.read<ApiKeyProvider>();
    final apiKey = apiKeyProvider.keyFor(provider);
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.toolMissingApiKey(provider.displayName))),
      );
      return;
    }

    final hasImageInput = widget.tool.inputFields.any((f) => f.type == 'image');
    if (!hasImageInput) {
      final suffix = apiKey.length > 4 ? apiKey.substring(apiKey.length - 4) : apiKey;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.toolApiKeyInUse(provider.displayName, suffix))),
      );
      return;
    }

    final imageField = widget.tool.inputFields.firstWhere((f) => f.type == 'image');
    final imageValue = _inputValues[imageField.id];
    if (imageValue == null || !imageValue.hasBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.toolImageRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final suffix = apiKey.length > 4 ? apiKey.substring(apiKey.length - 4) : apiKey;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.toolApiKeyInUse(provider.displayName, suffix))),
      );

      final promptBuffer = StringBuffer();
      final basePrompt = widget.tool.prompt?.trim();
      if (basePrompt != null && basePrompt.isNotEmpty) {
        promptBuffer.writeln(basePrompt);
      } else {
        promptBuffer.writeln(
          'Turn this photo into a whimsical Studio Ghibli style illustration with rich colors and soft lighting.',
        );
      }

      final additionalInstructions = widget.tool.inputFields
          .where((f) => f.type == 'text')
          .map((f) => _inputValues[f.id]?.text)
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

      if (additionalInstructions.isNotEmpty) {
        promptBuffer
          ..writeln()
          ..writeln('Additional instructions:')
          ..writeln(additionalInstructions.join('\n'));
      }

      final generatedImage = await _generateStylizedImage(
        provider: provider,
        apiKey: apiKey,
        imageBytes: imageValue.bytes!,
        imageMimeType: imageValue.mimeType ?? 'image/png',
        prompt: promptBuffer.toString(),
      );

      if (!mounted) return;

      final analysisResult = AnalysisResult(
        status: AnalysisStatus.success,
        subjectImageBytes: generatedImage,
        summary: l10n.toolImageResultSummary,
        meta: Meta(
          analyzedItemsCount: 1,
          timeRange: l10n.toolResultSingleImageRange,
          modelUsed: provider.displayName,
        ),
      );

      final historyInputs =
          _buildHistoryInputs(imageFieldId: imageField.id, imageValue: imageValue);
      final outputs = <String, dynamic>{
        'image': 'data:image/png;base64,${base64Encode(generatedImage)}',
      };

      final summary = analysisResult.summary;
      if (summary != null && summary.isNotEmpty) {
        outputs['summary'] = summary;
      }

      try {
        await context.read<HistoryProvider>().recordActivity(
              toolId: widget.tool.id,
              inputs: historyInputs,
              outputs: outputs,
            );
      } catch (_) {
        // History persistence failures should not block the result experience.
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            result: analysisResult,
            tool: widget.tool,
          ),
        ),
      );
    } on UnsupportedError catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.toolProviderUnsupported)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.toolRunFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Uint8List> _generateStylizedImage({
    required AiProvider provider,
    required String apiKey,
    required Uint8List imageBytes,
    required String imageMimeType,
    required String prompt,
  }) async {
    switch (provider) {
      case AiProvider.chatgpt:
        return _runOpenAiEdit(
          apiKey: apiKey,
          imageBytes: imageBytes,
          imageMimeType: imageMimeType,
          prompt: prompt,
        );
      case AiProvider.gemini:
      case AiProvider.grok:
        throw UnsupportedError('Provider not supported for this tool');
    }
  }

  Future<Uint8List> _runOpenAiEdit({
    required String apiKey,
    required Uint8List imageBytes,
    required String imageMimeType,
    required String prompt,
  }) async {
    final uri = Uri.parse('https://api.openai.com/v1/images/edits');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..headers['Accept'] = 'application/json'
      ..fields['prompt'] = prompt
      ..fields['size'] = '1024x1024'
      ..fields['n'] = '1'
      ..fields['response_format'] = 'b64_json'
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'upload.${_extensionFromMime(imageMimeType)}',
          contentType: MediaType.parse(imageMimeType),
        ),
      );

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 400) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) {
      throw Exception('No image data returned.');
    }

    final first = data.first as Map<String, dynamic>;
    final base64Image = first['b64_json'] as String?;
    if (base64Image == null) {
      throw Exception('Image payload missing.');
    }

    return base64Decode(base64Image);
  }

  String _extensionFromMime(String mime) {
    final lower = mime.toLowerCase();
    if (lower.endsWith('png')) return 'png';
    if (lower.endsWith('jpeg') || lower.endsWith('jpg')) return 'jpg';
    return 'png';
  }

  Map<String, dynamic> _buildHistoryInputs({
    required String imageFieldId,
    required ToolInputValue imageValue,
  }) {
    final inputs = <String, dynamic>{};

    for (final field in widget.tool.inputFields) {
      final value = _inputValues[field.id];
      if (field.type == 'text') {
        inputs[field.label] = value?.text ?? '';
      } else if (field.type == 'image' && field.id == imageFieldId) {
        inputs[field.label] = imageValue.fileName ?? 'photo';
      }
    }

    return inputs;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final favorites = context.watch<FavoriteToolsProvider>();
    final isFavorite = favorites.isFavorite(widget.tool.id);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            tooltip: isFavorite
                ? l10n.removeFromFavorites
                : l10n.addToFavorites,
            onPressed: () => favorites.toggleFavorite(widget.tool.id),
          ),
        ],
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

                  if (widget.tool.aiProvider != null) ...[
                    _SectionCard(
                      title: l10n.toolProviderLabel,
                      child: Consumer<ApiKeyProvider>(
                        builder: (context, apiKeys, _) {
                          final provider = widget.tool.aiProvider!;
                          final hasKey = (apiKeys.keyFor(provider) ?? '').isNotEmpty;
                          final status = hasKey
                              ? l10n.toolProviderStatusReady
                              : l10n.toolProviderStatusMissing;
                          final statusColor = hasKey
                              ? cs.primary
                              : Theme.of(context).colorScheme.error;
                          return Row(
                            children: [
                              Icon(
                                hasKey ? Icons.verified_user : Icons.warning_amber_outlined,
                                color: statusColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${provider.displayName} · $status',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (widget.tool.tags.isNotEmpty) ...[
                    _SectionCard(
                      title: l10n.tags,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in widget.tool.tags)
                            Chip(
                              label: Text(tag),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Feature Pills (now includes Credits pill) ---
                  if (widget.tool.featurePills.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Highlights',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...widget.tool.featurePills.map((pill) {
                            return FeaturePillWidget(
                              label: pill.label,
                              icon: IconMapper.getIcon(pill.icon),
                            );
                          }),
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
                            initialValue: _inputValues[field.id],
                            onChanged: (value) {
                              setState(() {
                                if (value.isEmpty) {
                                  _inputValues.remove(field.id);
                                } else {
                                  _inputValues[field.id] = value;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  FilledButton.icon(
                    onPressed: _isLoading ? null : _runTool,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(_isLoading ? l10n.analysisInProgress : l10n.toolRunButton),
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
                      color: cs.surfaceContainerHighest.withOpacity(0.45),
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
      color: cs.surfaceContainerHighest.withOpacity(0.18),
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
