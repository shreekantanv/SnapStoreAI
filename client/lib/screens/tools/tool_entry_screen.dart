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
  final Map<String, PageController> _carouselControllers = {};
  final Map<String, int> _carouselIndices = {};

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
  }

  @override
  void dispose() {
    _httpClient.close();
    for (final controller in _carouselControllers.values) {
      controller.dispose();
    }
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
    InputField? imageField;
    ToolInputValue? imageValue;

    if (widget.tool.runtime == ToolRuntime.imageStylization) {
      final hasImageInput = widget.tool.inputFields.any((f) => f.type == 'image');
      if (!hasImageInput) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.toolProviderUnsupported)),
        );
        return;
      }

      imageField = widget.tool.inputFields.firstWhere((f) => f.type == 'image');
      imageValue = _inputValues[imageField.id];
      if (imageValue == null || !imageValue.hasBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.toolImageRequired)),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    final suffix = apiKey.length > 4 ? apiKey.substring(apiKey.length - 4) : apiKey;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.toolApiKeyInUse(provider.displayName, suffix))),
      );

      switch (widget.tool.runtime) {
        case ToolRuntime.imageStylization:
          await _executeImageStylization(
            provider: provider,
            apiKey: apiKey,
            imageField: imageField!,
            imageValue: imageValue!,
            l10n: l10n,
          );
          break;
        case ToolRuntime.storybookGenerator:
          await _executeStorybookGeneration(
            provider: provider,
            apiKey: apiKey,
            l10n: l10n,
          );
          break;
      }
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

  Future<void> _executeImageStylization({
    required AiProvider provider,
    required String apiKey,
    required InputField imageField,
    required ToolInputValue imageValue,
    required AppLocalizations l10n,
  }) async {
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
  }

  Future<void> _executeStorybookGeneration({
    required AiProvider provider,
    required String apiKey,
    required AppLocalizations l10n,
  }) async {
    if (provider != AiProvider.gemini) {
      throw UnsupportedError('Provider not supported for this tool');
    }

    final prompt = _buildStoryPrompt();
    final story = await _generateStorybook(
      apiKey: apiKey,
      prompt: prompt,
    );

    if (!mounted) return;

    final trimmedStory = story.trim();
    final analysisResult = AnalysisResult(
      status: AnalysisStatus.success,
      summary: trimmedStory.isEmpty ? null : trimmedStory,
      meta: Meta(
        analyzedItemsCount: 1,
        timeRange: l10n.toolResultSingleImageRange,
        modelUsed: provider.displayName,
      ),
    );

    final historyInputs = _buildHistoryInputs();
    final outputs = <String, dynamic>{};
    if (trimmedStory.isNotEmpty) {
      outputs['story'] = trimmedStory;
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
  }

  String _buildStoryPrompt() {
    final buffer = StringBuffer();
    final basePrompt = widget.tool.prompt?.trim();
    final hasCustomPrompt = basePrompt != null && basePrompt.isNotEmpty;
    if (hasCustomPrompt) {
      buffer.writeln(basePrompt);
    } else {
      buffer.writeln(
        'You are a world-class children\'s author. Write a vibrant, picture-book style story for young readers.',
      );
      buffer.writeln(
        'Structure the response with a title, three short chapters, and a closing section titled "Story Moral".',
      );
      buffer.writeln(
        'After each chapter, include a single-sentence illustration idea prefixed with "Illustration:".',
      );
    }

    final textInputs = widget.tool.inputFields
        .where((field) => field.type == 'text')
        .map((field) {
      final value = _inputValues[field.id]?.text?.trim();
      if (value == null || value.isEmpty) {
        return null;
      }
      return '${field.label}: $value';
    }).whereType<String>().toList();

    if (textInputs.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Story parameters:')
        ..writeln(textInputs.join('\n'));
    }

    return buffer.toString();
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

  Future<String> _generateStorybook({
    required String apiKey,
    required String prompt,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
    );

    final response = await _httpClient.post(
      uri.replace(queryParameters: {'key': apiKey}),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.85,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;

    final promptFeedback = decoded['promptFeedback'];
    if (promptFeedback is Map) {
      final blockReason = (promptFeedback['blockReason'] as String?)?.trim();
      if (blockReason != null && blockReason.isNotEmpty) {
        throw Exception('Request blocked: $blockReason');
      }
    }

    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No story content returned.');
    }

    for (final candidate in candidates) {
      if (candidate is! Map) continue;
      final content = candidate['content'];
      if (content is! Map) continue;
      final parts = content['parts'];
      if (parts is! List) continue;

      for (final part in parts) {
        if (part is! Map) continue;
        final text = (part['text'] as String?)?.trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
    }

    throw Exception('Story content missing.');
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
    String? imageFieldId,
    ToolInputValue? imageValue,
  }) {
    final inputs = <String, dynamic>{};

    for (final field in widget.tool.inputFields) {
      final value = _inputValues[field.id];
      if (field.type == 'text') {
        final textValue = value?.text?.trim();
        if (textValue != null && textValue.isNotEmpty) {
          inputs[field.label] = textValue;
        }
      } else if (field.type == 'image') {
        if (imageFieldId != null &&
            imageValue != null &&
            field.id == imageFieldId &&
            imageValue.hasBytes) {
          inputs[field.label] = imageValue.fileName ?? 'photo';
        } else if (value != null && value.hasBytes) {
          inputs[field.label] = value.fileName ?? 'photo';
        }
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
                  Builder(
                    builder: (context) {
                      final otherFields = <InputField>[];
                      final groupDrafts = <String, _CarouselGroupDraft>{};
                      final groupOrder = <String>[];
                      final profilePattern = RegExp(r'^profile(\d+)_');

                      for (final field in widget.tool.inputFields) {
                        final ui = field.ui;
                        final variant = ui?.variant?.toLowerCase();
                        final hasCarouselUi =
                            variant == 'carousel' && ui?.groupId != null && ui?.groupItemId != null;

                        if (!hasCarouselUi) {
                          final legacyMatch = profilePattern.firstMatch(field.id);
                          if (legacyMatch != null) {
                            final rawIndex = legacyMatch.group(1)!;
                            final numericIndex = int.tryParse(rawIndex);
                            final displayIndex =
                                (numericIndex != null && numericIndex > 0)
                                    ? '$numericIndex'
                                    : rawIndex;
                            final pageIndexValue = numericIndex != null
                                ? numericIndex.toDouble()
                                : double.tryParse(rawIndex) ?? 0.0;
                            final syntheticOptions = <String, dynamic>{
                              'itemLabel': 'Profile',
                              'pageIndex': pageIndexValue,
                              'previousTooltip': 'Previous profile',
                              'nextTooltip': 'Next profile',
                            };
                            final syntheticUi = InputFieldUiConfig(
                              variant: 'carousel',
                              groupId: 'profiles',
                              groupLabel: 'Profiles',
                              groupItemId: 'profile$rawIndex',
                              groupItemLabel: 'Profile $displayIndex',
                              options: Map<String, dynamic>.unmodifiable(syntheticOptions),
                            );
                            final draft = groupDrafts.putIfAbsent(
                              syntheticUi.groupId!,
                              () {
                                groupOrder.add(syntheticUi.groupId!);
                                return _CarouselGroupDraft(id: syntheticUi.groupId!);
                              },
                            );
                            draft.applyUi(syntheticUi);
                            draft.addField(field, overrideUi: syntheticUi);
                            continue;
                          }

                          otherFields.add(field);
                          continue;
                        }

                        final groupId = ui!.groupId!;
                        final draft = groupDrafts.putIfAbsent(groupId, () {
                          groupOrder.add(groupId);
                          return _CarouselGroupDraft(id: groupId);
                        });
                        draft.applyUi(ui);
                        draft.addField(field);
                      }

                      final carouselGroups = <_CarouselGroupData>[];
                      for (final id in groupOrder) {
                        final group = groupDrafts[id]?.build();
                        if (group != null) {
                          carouselGroups.add(group);
                        }
                      }

                      _syncCarouselControllers(
                          carouselGroups.map((group) => group.id).toSet());

                      Widget buildOtherFields() {
                        return Column(
                          children: [
                            for (final field in otherFields) ...[
                              _buildInputField(field),
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }

                      if (carouselGroups.isEmpty) {
                        return _SectionCard(
                          title: 'Input Fields',
                          child: buildOtherFields(),
                        );
                      }

                      final inputSections = <Widget>[];

                      if (otherFields.isNotEmpty) {
                        inputSections
                          ..add(
                            _SectionCard(
                              title: 'Input Fields',
                              child: buildOtherFields(),
                            ),
                          )
                          ..add(const SizedBox(height: 16));
                      }

                      for (var i = 0; i < carouselGroups.length; i++) {
                        final group = carouselGroups[i];
                        final pageCount = group.pages.length;
                        if (pageCount == 0) {
                          continue;
                        }

                        final previousIndex = _carouselIndices[group.id];
                        final clampedIndex =
                            (previousIndex ?? 0).clamp(0, pageCount - 1);
                        final existingController = _carouselControllers[group.id];

                        if (existingController == null) {
                          _carouselControllers[group.id] =
                              PageController(initialPage: clampedIndex);
                        } else if (previousIndex != null &&
                            clampedIndex != previousIndex) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            final controller = _carouselControllers[group.id];
                            if (controller != null && controller.hasClients) {
                              controller.jumpToPage(clampedIndex);
                            }
                          });
                        }

                        _carouselIndices[group.id] = clampedIndex;
                        final controller = _carouselControllers[group.id]!;

                        inputSections.add(
                          _SectionCard(
                            title: group.title ?? 'Inputs',
                            child: _InputCarousel(
                              controller: controller,
                              currentIndex: clampedIndex,
                              onIndexChanged: (index) {
                                setState(() {
                                  _carouselIndices[group.id] = index;
                                });
                              },
                              options: group.options,
                              pages: group.pages,
                              buildField: _buildInputField,
                            ),
                          ),
                        );

                        if (i != carouselGroups.length - 1) {
                          inputSections.add(const SizedBox(height: 16));
                        }
                      }

                      if (inputSections.isEmpty) {
                        return _SectionCard(
                          title: 'Input Fields',
                          child: buildOtherFields(),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: inputSections,
                      );
                    },
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

  void _syncCarouselControllers(Set<String> activeGroupIds) {
    final keysToRemove = _carouselControllers.keys
        .where((key) => !activeGroupIds.contains(key))
        .toList(growable: false);
    for (final key in keysToRemove) {
      _carouselControllers.remove(key)?.dispose();
      _carouselIndices.remove(key);
    }
  }

  Widget _buildInputField(InputField field) {
    return DynamicInputWidget(
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
    );
  }
}

class _CarouselGroupDraft {
  _CarouselGroupDraft({required this.id});

  final String id;
  String? title;
  String? itemLabel;
  String? pageTitleTemplate;
  bool? showPageIndicator;
  double? pageHeight;
  String? previousTooltip;
  String? nextTooltip;
  final Map<String, _CarouselPageDraft> _pages = {};
  final List<_CarouselPageDraft> _orderedPages = [];

  static String? _cleanString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) {
      final doubleValue = value.toDouble();
      return doubleValue.isFinite ? doubleValue : null;
    }
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null && parsed.isFinite) {
        return parsed;
      }
    }
    return null;
  }

  void applyUi(InputFieldUiConfig ui) {
    title = ui.groupLabel ?? title;

    final options = ui.options;
    final labelOption = _cleanString(options['itemLabel']);
    if (labelOption != null) {
      itemLabel = labelOption;
    }

    final templateOption = _cleanString(options['pageTitleTemplate']);
    if (templateOption != null) {
      pageTitleTemplate = templateOption;
    }

    final indicatorOption = _parseBool(options['showPageIndicator']);
    if (indicatorOption != null) {
      showPageIndicator = indicatorOption;
    }

    final heightOption = _parseDouble(options['pageHeight']);
    if (heightOption != null) {
      pageHeight = heightOption;
    }

    final prevTooltipOption = _cleanString(options['previousTooltip']);
    if (prevTooltipOption != null) {
      previousTooltip = prevTooltipOption;
    }

    final nextTooltipOption = _cleanString(options['nextTooltip']);
    if (nextTooltipOption != null) {
      nextTooltip = nextTooltipOption;
    }
  }

  void addField(InputField field, {InputFieldUiConfig? overrideUi}) {
    final ui = overrideUi ?? field.ui;
    if (ui == null || ui.groupItemId == null) {
      return;
    }

    final pageId = ui.groupItemId!;
    final page = _pages.putIfAbsent(pageId, () {
      final draft =
          _CarouselPageDraft(id: pageId, insertionIndex: _orderedPages.length);
      _orderedPages.add(draft);
      return draft;
    });

    final label = ui.groupItemLabel;
    if (label != null && label.trim().isNotEmpty) {
      page.label = label.trim();
    }

    final sortKey = _parseDouble(ui.options['order']) ??
        _parseDouble(ui.options['pageIndex']) ??
        _parseDouble(ui.options['sortKey']);
    if (sortKey != null) {
      page.sortKey = sortKey;
    } else if (page.sortKey == null) {
      final numericMatch = RegExp(r'\d+').firstMatch(pageId);
      if (numericMatch != null) {
        final numeric = double.tryParse(numericMatch.group(0)!);
        if (numeric != null) {
          page.sortKey = numeric;
        }
      }
    }

    page.fields.add(field);
  }

  _CarouselGroupData? build() {
    final orderedDrafts = List<_CarouselPageDraft>.from(_orderedPages)
      ..sort((a, b) {
        final ak = a.sortKey;
        final bk = b.sortKey;
        if (ak != null && bk != null && ak != bk) {
          return ak.compareTo(bk);
        }
        if (ak != null && bk == null) {
          return -1;
        }
        if (ak == null && bk != null) {
          return 1;
        }
        return a.insertionIndex.compareTo(b.insertionIndex);
      });

    final pages = <_CarouselPage>[];
    for (final draft in orderedDrafts) {
      if (draft.fields.isEmpty) continue;
      pages.add(
        _CarouselPage(
          id: draft.id,
          label: draft.label,
          fields: List<InputField>.unmodifiable(draft.fields),
        ),
      );
    }

    if (pages.isEmpty) {
      return null;
    }

    String? resolvedLabel = itemLabel;
    if ((resolvedLabel == null || resolvedLabel.trim().isEmpty) &&
        title != null && title!.trim().isNotEmpty) {
      final trimmed = title!.trim();
      if (trimmed.length > 1 && trimmed.endsWith('s')) {
        resolvedLabel = trimmed.substring(0, trimmed.length - 1);
      } else {
        resolvedLabel = trimmed;
      }
    }

    final resolvedItemLabel =
        (resolvedLabel != null && resolvedLabel.trim().isNotEmpty)
            ? resolvedLabel.trim()
            : 'Item';

    final double baseHeight = pageHeight ?? 420;
    final resolvedHeight =
        baseHeight.isFinite && baseHeight > 120 ? baseHeight : 420;

    return _CarouselGroupData(
      id: id,
      title: title,
      options: _CarouselUiOptions(
        itemLabel: resolvedItemLabel,
        pageTitleTemplate: pageTitleTemplate?.trim().isEmpty ?? true
            ? null
            : pageTitleTemplate!.trim(),
        showPageIndicator: showPageIndicator ?? true,
        height: resolvedHeight,
        previousTooltip: previousTooltip,
        nextTooltip: nextTooltip,
      ),
      pages: List<_CarouselPage>.unmodifiable(pages),
    );
  }
}

class _CarouselPageDraft {
  _CarouselPageDraft({required this.id, required this.insertionIndex});

  final String id;
  final int insertionIndex;
  String? label;
  double? sortKey;
  final List<InputField> fields = [];
}

class _CarouselGroupData {
  const _CarouselGroupData({
    required this.id,
    this.title,
    required this.options,
    required this.pages,
  });

  final String id;
  final String? title;
  final _CarouselUiOptions options;
  final List<_CarouselPage> pages;
}

class _CarouselPage {
  const _CarouselPage({
    required this.id,
    this.label,
    required this.fields,
  });

  final String id;
  final String? label;
  final List<InputField> fields;
}

class _CarouselUiOptions {
  const _CarouselUiOptions({
    required this.itemLabel,
    this.pageTitleTemplate,
    required this.showPageIndicator,
    required this.height,
    this.previousTooltip,
    this.nextTooltip,
  }) : assert(height > 0);

  final String itemLabel;
  final String? pageTitleTemplate;
  final bool showPageIndicator;
  final double height;
  final String? previousTooltip;
  final String? nextTooltip;
}

class _InputCarousel extends StatefulWidget {
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final _CarouselUiOptions options;
  final List<_CarouselPage> pages;
  final Widget Function(InputField field) buildField;

  const _InputCarousel({
    required this.controller,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.options,
    required this.pages,
    required this.buildField,
  });

  @override
  State<_InputCarousel> createState() => _InputCarouselState();
}

class _InputCarouselState extends State<_InputCarousel> {
  late int _activeIndex;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.pages.isEmpty
        ? 0
        : widget.currentIndex.clamp(0, widget.pages.length - 1);
    widget.controller.addListener(_handlePageChange);
  }

  @override
  void didUpdateWidget(covariant _InputCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handlePageChange);
      widget.controller.addListener(_handlePageChange);
    }

    final maxIndex = widget.pages.isEmpty ? 0 : widget.pages.length - 1;
    final desiredIndex = widget.pages.isEmpty
        ? 0
        : widget.currentIndex.clamp(0, maxIndex);

    if (desiredIndex != _activeIndex) {
      setState(() {
        _activeIndex = desiredIndex;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.controller.hasClients) return;
        widget.controller.jumpToPage(desiredIndex);
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handlePageChange);
    super.dispose();
  }

  void _handlePageChange() {
    final page = widget.controller.page;
    if (page == null) return;
    final rounded = page.round();
    if (rounded == _activeIndex || rounded < 0 || rounded >= widget.pages.length) {
      return;
    }
    setState(() {
      _activeIndex = rounded;
    });
    widget.onIndexChanged(rounded);
  }

  void _goTo(int delta) {
    if (widget.pages.isEmpty) return;
    final target = (_activeIndex + delta).clamp(0, widget.pages.length - 1);
    if (target == _activeIndex) return;
    widget.controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  String _headerTextFor(int index) {
    if (widget.pages.isEmpty) {
      return widget.options.itemLabel;
    }

    final total = widget.pages.length;
    final page = widget.pages[index];
    final label = page.label?.trim();
    final defaultText = label != null && label.isNotEmpty
        ? label
        : '${widget.options.itemLabel} ${index + 1} of $total';

    final template = widget.options.pageTitleTemplate;
    if (template == null || template.isEmpty) {
      return defaultText;
    }

    var resolved = template
        .replaceAll('{index}', '${index + 1}')
        .replaceAll('{current}', '${index + 1}')
        .replaceAll('{total}', '$total')
        .replaceAll('{label}', label ?? '')
        .replaceAll('{itemLabel}', widget.options.itemLabel)
        .replaceAll('{itemLabelLower}', widget.options.itemLabel.toLowerCase())
        .replaceAll('{default}', defaultText);

    resolved = resolved.trim();
    return resolved.isEmpty ? defaultText : resolved;
  }

  String _tooltipText(String action, String? override) {
    if (override != null && override.trim().isNotEmpty) {
      return override;
    }
    final noun = widget.options.itemLabel.isEmpty
        ? 'item'
        : widget.options.itemLabel.toLowerCase();
    return '$action $noun';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return const SizedBox.shrink();
    }

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final header = _headerTextFor(_activeIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                header,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: _activeIndex > 0 ? () => _goTo(-1) : null,
              tooltip: _tooltipText('Previous', widget.options.previousTooltip),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onPressed: _activeIndex < widget.pages.length - 1
                  ? () => _goTo(1)
                  : null,
              tooltip: _tooltipText('Next', widget.options.nextTooltip),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: widget.options.height,
          child: PageView.builder(
            controller: widget.controller,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.pages.length,
            itemBuilder: (context, index) {
              final page = widget.pages[index];
              final fields = page.fields;
              return SingleChildScrollView(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: [
                    for (int i = 0; i < fields.length; i++) ...[
                      widget.buildField(fields[i]),
                      if (i != fields.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.options.showPageIndicator && widget.pages.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.pages.length; i++) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: i == _activeIndex ? 20 : 8,
                  decoration: BoxDecoration(
                    color: i == _activeIndex
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
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
