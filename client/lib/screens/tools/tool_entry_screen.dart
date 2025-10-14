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
  final Map<String, int> _wizardIndices = {};

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
                      final carouselDrafts = <String, _CarouselGroupDraft>{};
                      final carouselOrder = <String>[];
                      final wizardDrafts = <String, _WizardGroupDraft>{};
                      final wizardOrder = <String>[];
                      final profilePattern = RegExp(r'^profile(\d+)_');

                      for (final field in widget.tool.inputFields) {
                        final assignment = _resolveWizardAssignment(
                          field,
                          profilePattern: profilePattern,
                        );
                        if (assignment != null) {
                          final draft = wizardDrafts.putIfAbsent(
                            assignment.groupId,
                            () {
                              final draft = _WizardGroupDraft(
                                id: assignment.groupId,
                                insertionIndex: wizardOrder.length,
                              );
                              wizardOrder.add(assignment.groupId);
                              return draft;
                            },
                          );
                          draft.applyAssignment(assignment);
                          draft.addField(
                            field,
                            assignment: assignment,
                            profilePattern: profilePattern,
                          );
                          continue;
                        }

                        final handledByCarousel = _registerCarouselField(
                          field: field,
                          drafts: carouselDrafts,
                          order: carouselOrder,
                          profilePattern: profilePattern,
                        );
                        if (handledByCarousel) {
                          continue;
                        }

                        otherFields.add(field);
                      }

                      final wizardGroups = <_WizardGroupData>[];
                      for (final id in wizardOrder) {
                        final group = wizardDrafts[id]?.build();
                        if (group != null) {
                          wizardGroups.add(group);
                        }
                      }
                      wizardGroups.sort((a, b) {
                        final ao = a.order;
                        final bo = b.order;
                        if (ao != null && bo != null && ao != bo) {
                          return ao.compareTo(bo);
                        }
                        if (ao != null && bo == null) {
                          return -1;
                        }
                        if (ao == null && bo != null) {
                          return 1;
                        }
                        return a.insertionIndex.compareTo(b.insertionIndex);
                      });

                      final carouselGroups = <_CarouselGroupData>[];
                      for (final id in carouselOrder) {
                        final group = carouselDrafts[id]?.build();
                        if (group != null) {
                          carouselGroups.add(group);
                        }
                      }

                      final activeCarouselGroupIds = <String>{};
                      for (final group in wizardGroups) {
                        for (final step in group.steps) {
                          for (final carousel in step.carousels) {
                            activeCarouselGroupIds.add(carousel.id);
                          }
                        }
                      }
                      for (final group in carouselGroups) {
                        activeCarouselGroupIds.add(group.id);
                      }
                      _syncCarouselControllers(activeCarouselGroupIds);
                      _syncWizardIndices(wizardGroups.map((group) => group.id).toSet());

                      Widget buildOtherFields() {
                        return Column(
                          children: [
                            for (var i = 0; i < otherFields.length; i++) ...[
                              _buildInputField(otherFields[i]),
                              if (i != otherFields.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }

                      final sections = <Widget>[];
                      void addSection(Widget section) {
                        if (sections.isNotEmpty) {
                          sections.add(const SizedBox(height: 16));
                        }
                        sections.add(section);
                      }

                      for (final group in wizardGroups) {
                        addSection(
                          _SectionCard(
                            title: group.title ?? 'Guided setup',
                            child: _buildWizardGroup(group),
                          ),
                        );
                      }

                      for (final group in carouselGroups) {
                        final state = _resolveCarouselState(group);
                        if (state == null) {
                          continue;
                        }

                        addSection(
                          _SectionCard(
                            title: group.title ?? 'Inputs',
                            child: _InputCarousel(
                              controller: state.controller,
                              currentIndex: state.currentIndex,
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
                      }

                      if (otherFields.isNotEmpty) {
                        final baseTitle = (wizardGroups.isNotEmpty || carouselGroups.isNotEmpty)
                            ? 'Additional inputs'
                            : 'Input Fields';
                        addSection(
                          _SectionCard(
                            title: baseTitle,
                            child: buildOtherFields(),
                          ),
                        );
                      }

                      if (sections.isEmpty) {
                        return _SectionCard(
                          title: 'Input Fields',
                          child: buildOtherFields(),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: sections,
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

  void _syncWizardIndices(Set<String> activeGroupIds) {
    final keysToRemove = _wizardIndices.keys
        .where((key) => !activeGroupIds.contains(key))
        .toList(growable: false);
    for (final key in keysToRemove) {
      _wizardIndices.remove(key);
    }
  }

  _CarouselState? _resolveCarouselState(_CarouselGroupData group) {
    final pageCount = group.pages.length;
    if (pageCount == 0) {
      _carouselControllers.remove(group.id)?.dispose();
      _carouselIndices.remove(group.id);
      return null;
    }

    final previousIndex = _carouselIndices[group.id];
    final clampedIndex = (previousIndex ?? 0).clamp(0, pageCount - 1);
    final existingController = _carouselControllers[group.id];

    if (existingController == null) {
      _carouselControllers[group.id] = PageController(initialPage: clampedIndex);
    } else if (previousIndex != null && clampedIndex != previousIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final controller = _carouselControllers[group.id];
        if (controller != null && controller.hasClients) {
          controller.jumpToPage(clampedIndex);
        }
      });
    }

    _carouselIndices[group.id] = clampedIndex;
    return _CarouselState(
      controller: _carouselControllers[group.id]!,
      currentIndex: clampedIndex,
    );
  }

  Widget _buildWizardGroup(_WizardGroupData group) {
    final totalSteps = group.steps.length;
    if (totalSteps == 0) {
      return const SizedBox.shrink();
    }

    var index = _wizardIndices[group.id] ?? 0;
    index = index.clamp(0, totalSteps - 1);
    if (_wizardIndices[group.id] != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _wizardIndices[group.id] = index;
      });
    }

    final step = group.steps[index];
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final children = <Widget>[];

    if (group.subtitle != null && group.subtitle!.trim().isNotEmpty) {
      children.add(
        Text(
          group.subtitle!,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.75),
            height: 1.3,
          ),
        ),
      );
      children.add(const SizedBox(height: 12));
    }

    final showProgress = group.options.showProgressIndicator && totalSteps > 1;
    if (showProgress) {
      children.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (index + 1) / totalSteps,
                minHeight: 6,
                backgroundColor: cs.surfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Step ${index + 1} of $totalSteps',
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    } else {
      children.add(
        Text(
          'Step ${index + 1} of $totalSteps',
          style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }

    children.add(const SizedBox(height: 8));

    final stepTitle = step.title ?? 'Step ${index + 1}';
    children.add(
      Text(
        stepTitle,
        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );

    if (step.description != null && step.description!.trim().isNotEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(
        Text(
          step.description!,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.78),
            height: 1.35,
          ),
        ),
      );
    }

    final contentWidgets = <Widget>[];
    for (final carousel in step.carousels) {
      final state = _resolveCarouselState(carousel);
      if (state == null) continue;

      if (carousel.title != null && carousel.title!.trim().isNotEmpty) {
        contentWidgets.add(
          Text(
            carousel.title!,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        );
        contentWidgets.add(const SizedBox(height: 8));
      }

      contentWidgets.add(
        _InputCarousel(
          controller: state.controller,
          currentIndex: state.currentIndex,
          onIndexChanged: (value) {
            setState(() {
              _carouselIndices[carousel.id] = value;
            });
          },
          options: carousel.options,
          pages: carousel.pages,
          buildField: _buildInputField,
        ),
      );
      contentWidgets.add(const SizedBox(height: 16));
    }

    for (var i = 0; i < step.fields.length; i++) {
      contentWidgets.add(_buildInputField(step.fields[i]));
      if (i != step.fields.length - 1) {
        contentWidgets.add(const SizedBox(height: 12));
      }
    }

    if (contentWidgets.isNotEmpty) {
      children.add(const SizedBox(height: 16));
      children.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: contentWidgets,
        ),
      );
    }

    final isFirst = index == 0;
    final isLast = index == totalSteps - 1;

    final previousLabel = step.previousLabel ?? group.options.previousLabel;
    final nextLabel = isLast
        ? (step.doneLabel ?? group.options.doneLabel)
        : (step.nextLabel ?? group.options.nextLabel);

    final backAction = (!isFirst && !_isLoading)
        ? () => setState(() => _wizardIndices[group.id] = index - 1)
        : null;

    VoidCallback? primaryAction;
    if (_isLoading) {
      primaryAction = null;
    } else if (isLast) {
      primaryAction = _runTool;
    } else {
      primaryAction = () {
        setState(() => _wizardIndices[group.id] = index + 1);
      };
    }

    Widget buildPrimaryChild() {
      if (_isLoading && isLast) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Generating...'),
          ],
        );
      }
      return Text(nextLabel);
    }

    children.add(const SizedBox(height: 20));
    children.add(
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: backAction,
              child: Text(previousLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: primaryAction,
              child: buildPrimaryChild(),
            ),
          ),
        ],
      ),
    );

    if (isLast && !_isLoading) {
      children.add(const SizedBox(height: 12));
      children.add(
        Text(
          'Ready to generate your story. You can also adjust earlier steps or use the run button below.',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.65),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  _WizardAssignment? _resolveWizardAssignment(
    InputField field, {
    required RegExp profilePattern,
  }) {
    final metadataAssignment = _WizardAssignment.fromUi(field);
    if (metadataAssignment != null) {
      return metadataAssignment;
    }

    if (widget.tool.runtime == ToolRuntime.storybookGenerator) {
      return _storybookWizardAssignment(
        field,
        profilePattern: profilePattern,
      );
    }

    return null;
  }

  _WizardAssignment? _storybookWizardAssignment(
    InputField field, {
    required RegExp profilePattern,
  }) {
    const wizardId = 'storybook_daily_wizard';
    const wizardLabel = 'Guided story setup';
    const wizardDescription =
        'Work through a few focused steps so the storybook has everything it needs.';

    const basicsFields = {
      'seriesId',
      'date',
      'readingLevel',
      'language',
      'bilingual',
    };

    const profileExtras = {
      'heroProfileId',
      'supportingProfileIds',
    };

    const momentsFields = {
      'memoriesToday',
      'place',
      'feeling',
      'moral',
      'objectOfTheDay',
      'photoMomentUploads',
      'photoMomentUrls',
    };

    const styleFields = {
      'artStyle',
      'backgroundVibe',
      'pages',
      'narration',
      'narratorVoice',
      'continuityMode',
      'continueFromStoryId',
    };

    if (basicsFields.contains(field.id)) {
      return _WizardAssignment(
        groupId: wizardId,
        groupLabel: wizardLabel,
        groupDescription: wizardDescription,
        groupOrder: 0,
        showProgress: true,
        previousLabel: 'Back',
        nextLabel: 'Next step',
        doneLabel: 'Generate story',
        stepId: 'basics',
        stepLabel: 'Story basics',
        stepDescription:
            'Set the series name, date, reading level, and language preferences.',
        stepOrder: 0,
      );
    }

    if (profilePattern.hasMatch(field.id) || profileExtras.contains(field.id)) {
      return _WizardAssignment(
        groupId: wizardId,
        groupLabel: wizardLabel,
        groupDescription: wizardDescription,
        groupOrder: 0,
        showProgress: true,
        previousLabel: 'Back',
        nextLabel: 'Next step',
        doneLabel: 'Generate story',
        stepId: 'profiles',
        stepLabel: 'Family profiles',
        stepDescription:
            'Add each family member, upload photos, and choose who stars in today\'s adventure.',
        stepOrder: 1,
        carouselGroupId: 'profiles',
        carouselGroupLabel: 'Family profiles',
        carouselItemLabel: 'Family member',
        carouselItemIdPrefix: 'profile',
        carouselPreviousTooltip: 'Previous family member',
        carouselNextTooltip: 'Next family member',
      );
    }

    if (momentsFields.contains(field.id)) {
      return _WizardAssignment(
        groupId: wizardId,
        groupLabel: wizardLabel,
        groupDescription: wizardDescription,
        groupOrder: 0,
        showProgress: true,
        previousLabel: 'Back',
        nextLabel: 'Next step',
        doneLabel: 'Generate story',
        stepId: 'moments',
        stepLabel: 'Today\'s memories',
        stepDescription:
            'Capture what happened today and share optional photos to inspire each scene.',
        stepOrder: 2,
      );
    }

    if (styleFields.contains(field.id)) {
      return _WizardAssignment(
        groupId: wizardId,
        groupLabel: wizardLabel,
        groupDescription: wizardDescription,
        groupOrder: 0,
        showProgress: true,
        previousLabel: 'Back',
        nextLabel: 'Next step',
        doneLabel: 'Generate story',
        stepId: 'style',
        stepLabel: 'Style & extras',
        stepDescription:
            'Pick the art direction, backgrounds, narration, and continuity for this book.',
        stepOrder: 3,
        stepDoneLabel: 'Generate story',
      );
    }

    return null;
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

String? _cleanOptionString(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

bool? _parseOptionBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

double? _parseOptionDouble(dynamic value) {
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

bool _registerCarouselField({
  required InputField field,
  required Map<String, _CarouselGroupDraft> drafts,
  required List<String> order,
  required RegExp profilePattern,
  InputFieldUiConfig? overrideUi,
  String? fallbackGroupId,
  String? fallbackGroupLabel,
  String? fallbackItemLabel,
  String? fallbackItemIdPrefix,
  String? fallbackPreviousTooltip,
  String? fallbackNextTooltip,
}) {
  final ui = overrideUi ?? field.ui;
  final variant = ui?.variant?.toLowerCase();
  final hasCarouselUi =
      variant == 'carousel' && ui?.groupId != null && ui?.groupItemId != null;

  if (hasCarouselUi) {
    final groupId = ui!.groupId!;
    final draft = drafts.putIfAbsent(groupId, () {
      order.add(groupId);
      return _CarouselGroupDraft(id: groupId);
    });
    draft.applyUi(ui);
    draft.addField(field, overrideUi: overrideUi);
    return true;
  }

  if (overrideUi != null) {
    return false;
  }

  final legacyMatch = profilePattern.firstMatch(field.id);
  if (legacyMatch != null) {
    final rawIndex = legacyMatch.group(1)!;
    final numericIndex = int.tryParse(rawIndex);
    final displayIndex =
        (numericIndex != null && numericIndex > 0) ? '$numericIndex' : rawIndex;
    final groupId = fallbackGroupId ?? 'profiles';
    final groupLabel = fallbackGroupLabel ?? 'Profiles';
    final itemLabel = fallbackItemLabel ?? 'Profile';
    final itemIdPrefix = fallbackItemIdPrefix ?? 'profile';

    final syntheticOptions = <String, dynamic>{
      'itemLabel': itemLabel,
      'pageIndex': numericIndex != null
          ? numericIndex.toDouble()
          : double.tryParse(rawIndex) ?? 0.0,
    };

    final previousTooltip =
        fallbackPreviousTooltip ?? 'Previous ${itemLabel.toLowerCase()}';
    final nextTooltip =
        fallbackNextTooltip ?? 'Next ${itemLabel.toLowerCase()}';
    syntheticOptions['previousTooltip'] = previousTooltip;
    syntheticOptions['nextTooltip'] = nextTooltip;

    final syntheticUi = InputFieldUiConfig(
      variant: 'carousel',
      groupId: groupId,
      groupLabel: groupLabel,
      groupItemId: '$itemIdPrefix$rawIndex',
      groupItemLabel: '$itemLabel $displayIndex',
      options: Map<String, dynamic>.unmodifiable(syntheticOptions),
    );

    return _registerCarouselField(
      field: field,
      drafts: drafts,
      order: order,
      profilePattern: profilePattern,
      overrideUi: syntheticUi,
    );
  }

  return false;
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

  void applyUi(InputFieldUiConfig ui) {
    title = ui.groupLabel ?? title;

    final options = ui.options;
    final labelOption = _cleanOptionString(options['itemLabel']);
    if (labelOption != null) {
      itemLabel = labelOption;
    }

    final templateOption = _cleanOptionString(options['pageTitleTemplate']);
    if (templateOption != null) {
      pageTitleTemplate = templateOption;
    }

    final indicatorOption = _parseOptionBool(options['showPageIndicator']);
    if (indicatorOption != null) {
      showPageIndicator = indicatorOption;
    }

    final heightOption = _parseOptionDouble(options['pageHeight']);
    if (heightOption != null) {
      pageHeight = heightOption;
    }

    final prevTooltipOption = _cleanOptionString(options['previousTooltip']);
    if (prevTooltipOption != null) {
      previousTooltip = prevTooltipOption;
    }

    final nextTooltipOption = _cleanOptionString(options['nextTooltip']);
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

    final sortKey = _parseOptionDouble(ui.options['order']) ??
        _parseOptionDouble(ui.options['pageIndex']) ??
        _parseOptionDouble(ui.options['sortKey']);
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

class _CarouselState {
  const _CarouselState({
    required this.controller,
    required this.currentIndex,
  });

  final PageController controller;
  final int currentIndex;
}

class _WizardGroupDraft {
  _WizardGroupDraft({required this.id, required this.insertionIndex});

  final String id;
  final int insertionIndex;
  double? order;
  String? title;
  String? subtitle;
  bool? showProgressIndicator;
  String? previousLabel;
  String? nextLabel;
  String? doneLabel;

  final Map<String, _WizardStepDraft> _steps = {};
  final List<_WizardStepDraft> _orderedSteps = [];

  void applyAssignment(_WizardAssignment assignment) {
    final label = _cleanOptionString(assignment.groupLabel);
    if (label != null && title == null) {
      title = label;
    }

    final subtitleValue = _cleanOptionString(assignment.groupDescription);
    if (subtitleValue != null && subtitle == null) {
      subtitle = subtitleValue;
    }

    order ??= assignment.groupOrder;

    final progress = assignment.showProgress;
    if (progress != null && showProgressIndicator == null) {
      showProgressIndicator = progress;
    }

    final prev = _cleanOptionString(assignment.previousLabel);
    if (prev != null && previousLabel == null) {
      previousLabel = prev;
    }

    final next = _cleanOptionString(assignment.nextLabel);
    if (next != null && nextLabel == null) {
      nextLabel = next;
    }

    final done = _cleanOptionString(assignment.doneLabel);
    if (done != null && doneLabel == null) {
      doneLabel = done;
    }

    final stepDraft = _steps.putIfAbsent(assignment.stepId, () {
      final draft = _WizardStepDraft(
        id: assignment.stepId,
        insertionIndex: _orderedSteps.length,
      );
      _orderedSteps.add(draft);
      return draft;
    });

    stepDraft.applyAssignment(assignment);
  }

  void addField(
    InputField field, {
    required _WizardAssignment assignment,
    required RegExp profilePattern,
  }) {
    final stepDraft = _steps[assignment.stepId]!;
    final handled = _registerCarouselField(
      field: field,
      drafts: stepDraft.carouselDrafts,
      order: stepDraft.carouselOrder,
      profilePattern: profilePattern,
      fallbackGroupId: assignment.carouselGroupId,
      fallbackGroupLabel:
          assignment.carouselGroupLabel ?? assignment.stepLabel,
      fallbackItemLabel: assignment.carouselItemLabel,
      fallbackItemIdPrefix: assignment.carouselItemIdPrefix,
      fallbackPreviousTooltip: assignment.carouselPreviousTooltip,
      fallbackNextTooltip: assignment.carouselNextTooltip,
    );

    if (!handled) {
      stepDraft.fields.add(field);
    }
  }

  _WizardGroupData? build() {
    final orderedSteps = List<_WizardStepDraft>.from(_orderedSteps)
      ..sort((a, b) {
        final ao = a.order;
        final bo = b.order;
        if (ao != null && bo != null && ao != bo) {
          return ao.compareTo(bo);
        }
        if (ao != null && bo == null) {
          return -1;
        }
        if (ao == null && bo != null) {
          return 1;
        }
        return a.insertionIndex.compareTo(b.insertionIndex);
      });

    final builtSteps = <_WizardStepData>[];
    for (final draft in orderedSteps) {
      final step = draft.build();
      if (step != null) {
        builtSteps.add(step);
      }
    }

    if (builtSteps.isEmpty) {
      return null;
    }

    final options = _WizardGroupOptions(
      showProgressIndicator: showProgressIndicator ?? true,
      previousLabel: _cleanOptionString(previousLabel) ?? 'Back',
      nextLabel: _cleanOptionString(nextLabel) ?? 'Next step',
      doneLabel: _cleanOptionString(doneLabel) ?? 'Generate story',
    );

    return _WizardGroupData(
      id: id,
      insertionIndex: insertionIndex,
      order: order,
      title: title,
      subtitle: subtitle,
      options: options,
      steps: List<_WizardStepData>.unmodifiable(builtSteps),
    );
  }
}

class _WizardStepDraft {
  _WizardStepDraft({required this.id, required this.insertionIndex});

  final String id;
  final int insertionIndex;
  double? order;
  String? title;
  String? description;
  String? previousLabel;
  String? nextLabel;
  String? doneLabel;

  final List<InputField> fields = [];
  final Map<String, _CarouselGroupDraft> carouselDrafts = {};
  final List<String> carouselOrder = [];

  void applyAssignment(_WizardAssignment assignment) {
    order ??= assignment.stepOrder;

    final label = _cleanOptionString(assignment.stepLabel);
    if (label != null && title == null) {
      title = label;
    }

    final descriptionValue = _cleanOptionString(assignment.stepDescription);
    if (descriptionValue != null && description == null) {
      description = descriptionValue;
    }

    final prev = _cleanOptionString(assignment.stepPreviousLabel);
    if (prev != null && previousLabel == null) {
      previousLabel = prev;
    }

    final next = _cleanOptionString(assignment.stepNextLabel);
    if (next != null && nextLabel == null) {
      nextLabel = next;
    }

    final done = _cleanOptionString(assignment.stepDoneLabel);
    if (done != null && doneLabel == null) {
      doneLabel = done;
    }
  }

  _WizardStepData? build() {
    final carousels = <_CarouselGroupData>[];
    for (final id in carouselOrder) {
      final group = carouselDrafts[id]?.build();
      if (group != null) {
        carousels.add(group);
      }
    }

    if (fields.isEmpty && carousels.isEmpty) {
      return null;
    }

    return _WizardStepData(
      id: id,
      insertionIndex: insertionIndex,
      order: order,
      title: title,
      description: description,
      previousLabel: previousLabel,
      nextLabel: nextLabel,
      doneLabel: doneLabel,
      fields: List<InputField>.unmodifiable(fields),
      carousels: List<_CarouselGroupData>.unmodifiable(carousels),
    );
  }
}

class _WizardGroupData {
  const _WizardGroupData({
    required this.id,
    required this.insertionIndex,
    this.order,
    this.title,
    this.subtitle,
    required this.options,
    required this.steps,
  });

  final String id;
  final int insertionIndex;
  final double? order;
  final String? title;
  final String? subtitle;
  final _WizardGroupOptions options;
  final List<_WizardStepData> steps;
}

class _WizardStepData {
  const _WizardStepData({
    required this.id,
    required this.insertionIndex,
    this.order,
    this.title,
    this.description,
    this.previousLabel,
    this.nextLabel,
    this.doneLabel,
    required this.fields,
    required this.carousels,
  });

  final String id;
  final int insertionIndex;
  final double? order;
  final String? title;
  final String? description;
  final String? previousLabel;
  final String? nextLabel;
  final String? doneLabel;
  final List<InputField> fields;
  final List<_CarouselGroupData> carousels;
}

class _WizardGroupOptions {
  const _WizardGroupOptions({
    required this.showProgressIndicator,
    required this.previousLabel,
    required this.nextLabel,
    required this.doneLabel,
  });

  final bool showProgressIndicator;
  final String previousLabel;
  final String nextLabel;
  final String doneLabel;
}

class _WizardAssignment {
  const _WizardAssignment({
    required this.groupId,
    required this.stepId,
    this.groupLabel,
    this.groupDescription,
    this.groupOrder,
    this.showProgress,
    this.previousLabel,
    this.nextLabel,
    this.doneLabel,
    this.stepLabel,
    this.stepDescription,
    this.stepOrder,
    this.stepPreviousLabel,
    this.stepNextLabel,
    this.stepDoneLabel,
    this.carouselGroupId,
    this.carouselGroupLabel,
    this.carouselItemLabel,
    this.carouselItemIdPrefix,
    this.carouselPreviousTooltip,
    this.carouselNextTooltip,
  });

  final String groupId;
  final String stepId;
  final String? groupLabel;
  final String? groupDescription;
  final double? groupOrder;
  final bool? showProgress;
  final String? previousLabel;
  final String? nextLabel;
  final String? doneLabel;
  final String? stepLabel;
  final String? stepDescription;
  final double? stepOrder;
  final String? stepPreviousLabel;
  final String? stepNextLabel;
  final String? stepDoneLabel;
  final String? carouselGroupId;
  final String? carouselGroupLabel;
  final String? carouselItemLabel;
  final String? carouselItemIdPrefix;
  final String? carouselPreviousTooltip;
  final String? carouselNextTooltip;

  static _WizardAssignment? fromUi(InputField field) {
    final ui = field.ui;
    if (ui == null) {
      return null;
    }

    final options = ui.options;
    Map<String, dynamic>? wizardMap;
    final wizardOption = options['wizard'];
    if (wizardOption is Map<String, dynamic>) {
      wizardMap = wizardOption;
    }

    String? groupId = _cleanOptionString(options['wizardId']) ??
        _cleanOptionString(options['wizard']) ??
        _cleanOptionString(options['wizardGroup']) ??
        _cleanOptionString(options['flow']) ??
        _cleanOptionString(options['flowId']);
    if (groupId == null && wizardMap != null) {
      groupId = _cleanOptionString(wizardMap['id']) ??
          _cleanOptionString(wizardMap['group']) ??
          _cleanOptionString(wizardMap['groupId']) ??
          _cleanOptionString(wizardMap['flow']);
    }

    String? stepId = _cleanOptionString(options['wizardStepId']) ??
        _cleanOptionString(options['wizardStep']) ??
        _cleanOptionString(options['step']) ??
        _cleanOptionString(options['stepId']);
    if (stepId == null && wizardMap != null) {
      stepId = _cleanOptionString(wizardMap['step']) ??
          _cleanOptionString(wizardMap['stepId']);
    }

    final variant = ui.variant?.toLowerCase();
    if (variant == 'wizard') {
      groupId ??= _cleanOptionString(ui.groupId);
      stepId ??= _cleanOptionString(ui.groupItemId);
    }

    if (groupId == null || stepId == null) {
      return null;
    }

    String? groupLabel = _cleanOptionString(options['wizardLabel']) ??
        _cleanOptionString(options['wizardTitle']) ??
        _cleanOptionString(options['flowLabel']);
    if (groupLabel == null && wizardMap != null) {
      groupLabel = _cleanOptionString(wizardMap['label']) ??
          _cleanOptionString(wizardMap['title']);
    }
    if (groupLabel == null && variant == 'wizard') {
      groupLabel = _cleanOptionString(ui.groupLabel);
    }

    String? groupDescription =
        _cleanOptionString(options['wizardDescription']) ??
            _cleanOptionString(options['wizardSubtitle']);
    if (groupDescription == null && wizardMap != null) {
      groupDescription = _cleanOptionString(wizardMap['description']) ??
          _cleanOptionString(wizardMap['subtitle']);
    }

    final dynamic wizardOrderValue =
        wizardMap != null ? wizardMap['order'] : null;
    final dynamic wizardShowProgressValue =
        wizardMap != null ? wizardMap['showProgress'] : null;
    final dynamic wizardPrevValue =
        wizardMap != null ? wizardMap['previousLabel'] : null;
    final dynamic wizardNextValue =
        wizardMap != null ? wizardMap['nextLabel'] : null;
    final dynamic wizardDoneValue =
        wizardMap != null ? wizardMap['doneLabel'] : null;
    final dynamic wizardStepLabelValue =
        wizardMap != null ? wizardMap['stepLabel'] : null;
    final dynamic wizardStepTitleValue =
        wizardMap != null ? wizardMap['stepTitle'] : null;
    final dynamic wizardStepDescriptionValue =
        wizardMap != null ? wizardMap['stepDescription'] : null;
    final dynamic wizardStepOrderValue =
        wizardMap != null ? wizardMap['stepOrder'] : null;
    final dynamic wizardStepPrevValue =
        wizardMap != null ? wizardMap['stepPreviousLabel'] : null;
    final dynamic wizardStepNextValue =
        wizardMap != null ? wizardMap['stepNextLabel'] : null;
    final dynamic wizardStepDoneValue =
        wizardMap != null ? wizardMap['stepDoneLabel'] : null;
    final dynamic wizardCarouselIdValue =
        wizardMap != null ? wizardMap['carouselId'] : null;
    final dynamic wizardCarouselLabelValue =
        wizardMap != null ? wizardMap['carouselLabel'] : null;
    final dynamic wizardCarouselItemLabelValue =
        wizardMap != null ? wizardMap['carouselItemLabel'] : null;
    final dynamic wizardCarouselPrefixValue =
        wizardMap != null ? wizardMap['carouselItemPrefix'] : null;
    final dynamic wizardCarouselPrevTooltipValue =
        wizardMap != null ? wizardMap['carouselPreviousTooltip'] : null;
    final dynamic wizardCarouselNextTooltipValue =
        wizardMap != null ? wizardMap['carouselNextTooltip'] : null;

    final groupOrder = _parseOptionDouble(
      options['wizardOrder'] ?? options['flowOrder'] ?? wizardOrderValue,
    );
    final showProgress = _parseOptionBool(
      options['wizardShowProgress'] ??
          wizardShowProgressValue ??
          options['showProgress'],
    );
    final previousLabel = _cleanOptionString(
      options['wizardBackLabel'] ??
          options['wizardPreviousLabel'] ??
          options['previousLabel'] ??
          wizardPrevValue,
    );
    final nextLabel = _cleanOptionString(
      options['wizardNextLabel'] ?? options['nextLabel'] ?? wizardNextValue,
    );
    final doneLabel = _cleanOptionString(
      options['wizardDoneLabel'] ?? options['doneLabel'] ?? wizardDoneValue,
    );

    String? stepLabel = _cleanOptionString(
      options['wizardStepLabel'] ??
          options['wizardStepTitle'] ??
          options['stepLabel'] ??
          wizardStepLabelValue ??
          wizardStepTitleValue,
    );
    if (stepLabel == null) {
      stepLabel = _cleanOptionString(ui.groupItemLabel);
    }

    final stepDescription = _cleanOptionString(
      options['wizardStepDescription'] ??
          options['stepDescription'] ??
          wizardStepDescriptionValue,
    );

    final stepOrder = _parseOptionDouble(
      options['wizardStepOrder'] ??
          options['stepOrder'] ??
          wizardStepOrderValue,
    );
    final stepPreviousLabel = _cleanOptionString(
      options['wizardStepBackLabel'] ??
          options['stepPreviousLabel'] ??
          wizardStepPrevValue,
    );
    final stepNextLabel = _cleanOptionString(
      options['wizardStepNextLabel'] ??
          options['stepNextLabel'] ??
          wizardStepNextValue,
    );
    final stepDoneLabel = _cleanOptionString(
      options['wizardStepDoneLabel'] ??
          options['stepDoneLabel'] ??
          wizardStepDoneValue,
    );

    final carouselGroupId = _cleanOptionString(
      options['wizardCarouselId'] ??
          options['carouselGroupId'] ??
          wizardCarouselIdValue,
    );
    final carouselGroupLabel = _cleanOptionString(
      options['wizardCarouselLabel'] ??
          options['carouselGroupLabel'] ??
          wizardCarouselLabelValue,
    );
    final carouselItemLabel = _cleanOptionString(
      options['wizardCarouselItemLabel'] ??
          options['carouselItemLabel'] ??
          wizardCarouselItemLabelValue,
    );
    final carouselItemIdPrefix = _cleanOptionString(
      options['wizardCarouselItemPrefix'] ??
          options['carouselItemPrefix'] ??
          wizardCarouselPrefixValue,
    );
    final carouselPreviousTooltip = _cleanOptionString(
      options['wizardCarouselPreviousTooltip'] ??
          options['carouselPreviousTooltip'] ??
          wizardCarouselPrevTooltipValue,
    );
    final carouselNextTooltip = _cleanOptionString(
      options['wizardCarouselNextTooltip'] ??
          options['carouselNextTooltip'] ??
          wizardCarouselNextTooltipValue,
    );

    return _WizardAssignment(
      groupId: groupId,
      stepId: stepId,
      groupLabel: groupLabel,
      groupDescription: groupDescription,
      groupOrder: groupOrder,
      showProgress: showProgress,
      previousLabel: previousLabel,
      nextLabel: nextLabel,
      doneLabel: doneLabel,
      stepLabel: stepLabel,
      stepDescription: stepDescription,
      stepOrder: stepOrder,
      stepPreviousLabel: stepPreviousLabel,
      stepNextLabel: stepNextLabel,
      stepDoneLabel: stepDoneLabel,
      carouselGroupId: carouselGroupId,
      carouselGroupLabel: carouselGroupLabel,
      carouselItemLabel: carouselItemLabel,
      carouselItemIdPrefix: carouselItemIdPrefix,
      carouselPreviousTooltip: carouselPreviousTooltip,
      carouselNextTooltip: carouselNextTooltip,
    );
  }
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
