import 'dart:convert';
import 'dart:ui';

import 'package:client/screens/settings_screen.dart';
import 'package:client/screens/tools/tool_entry_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/tool.dart';
import '../models/tool_activity.dart';
import '../providers/favorite_tools_provider.dart';
import '../providers/history_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/tool_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/tool_widget.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = '';
  String _selectedCategory = 'All';
  int _currentNavIndex = 0;
  final Set<String> _selectedTags = <String>{};
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ToolProvider>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onToolTap(Tool tool) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ToolEntryScreen(tool: tool),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ToolProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final favoritesProvider = context.watch<FavoriteToolsProvider>();
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (prov.error != null && !prov.hasLoaded) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Unable to load tools',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We couldn\'t load the tool catalog right now.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                if (prov.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    prov.error.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurface.withOpacity(0.5)),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.read<ToolProvider>().refresh(),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!prov.hasLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allTools = prov.tools;
    final categorySet = <String>{
      ...allTools.expand((t) => t.categories),
    }..removeWhere((element) => element.trim().isEmpty);

    final categories = [
      'All',
      ...categorySet.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()))
    ];

    final tags = allTools
        .expand((t) => t.tags)
        .map((e) => e.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final filtered = allTools.where((t) {
      final q = _search.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty || t.title.toLowerCase().contains(q) || t.subtitle.toLowerCase().contains(q);
      final matchesCategory =
          _selectedCategory == 'All' || t.categories.contains(_selectedCategory);
      final matchesTags = _selectedTags.isEmpty || _selectedTags.every(t.tags.contains);
      return matchesSearch && matchesCategory && matchesTags;
    }).toList();

    final showFavoritesOnly = _currentNavIndex == 1;
    final displayTools = filtered
        .where((tool) => !showFavoritesOnly || favoritesProvider.isFavorite(tool.id))
        .toList();

    final gradients = Theme.of(context).extension<PremiumGradients>();
    final heroTitle = l10n.homeHeroGeneric;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradients?.scaffoldGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: BottomNavigationBar(
                backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.88),
                currentIndex: _currentNavIndex,
                onTap: (i) {
                  if (i == 3) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  } else {
                    if (i == 2) {
                      context.read<HistoryProvider>().fetchHistory();
                    }
                    setState(() => _currentNavIndex = i);
                  }
                },
                items: [
                  BottomNavigationBarItem(icon: const Icon(Icons.widgets), label: l10n.tools),
                  BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: l10n.favorites),
                  BottomNavigationBarItem(
                      icon: const Icon(Icons.history_toggle_off), label: l10n.history),
                  BottomNavigationBarItem(icon: const Icon(Icons.settings), label: l10n.settings),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                pinned: true,
                stretch: true,
                centerTitle: false,
                toolbarHeight: 86,
                backgroundColor: Colors.transparent,
                titleSpacing: 20,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      heroTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.homeHeroSubtitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (kDebugMode)
                    IconButton(
                      icon: const Icon(Icons.upload_file),
                      tooltip: 'Upload Tool JSON',
                      onPressed: () => Navigator.of(context).pushNamed('/admin/uploader'),
                    ),
                  IconButton(
                    icon: Icon(
                      themeProvider.themeMode == ThemeMode.light
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    tooltip: l10n.settings,
                    onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: l10n.settings,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
            body: CustomScrollView(
              slivers: _currentNavIndex == 2
                  ? _buildHistorySlivers(context, allTools)
                  : _buildToolSlivers(
                context: context,
                l10n: l10n,
                categories: categories,
                tags: tags,
                displayTools: displayTools,
                favoritesProvider: favoritesProvider,
                showFavoritesOnly: showFavoritesOnly,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildToolSlivers({
    required BuildContext context,
    required AppLocalizations l10n,
    required List<String> categories,
    required List<String> tags,
    required List<Tool> displayTools,
    required FavoriteToolsProvider favoritesProvider,
    required bool showFavoritesOnly,
  }) {
    final cs = Theme.of(context).colorScheme;
    final gradients = Theme.of(context).extension<PremiumGradients>();

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _HeroBanner(
            gradients: gradients,
            title: showFavoritesOnly ? l10n.favorites : l10n.premiumHighlights,
            subtitle: showFavoritesOnly ? l10n.favoritesCta : l10n.homeToolCount(displayTools.length),
            icon: showFavoritesOnly ? Icons.favorite : Icons.auto_awesome,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _SearchBar(
            controller: _searchCtrl,
            hint: l10n.searchForTools,
            onChanged: (v) => setState(() => _search = v),
            onClear: () {
              _searchCtrl.clear();
              setState(() => _search = '');
            },
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 46,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final cat = categories[i];
              final selected = cat == _selectedCategory;
              return ChoiceChip(
                selected: selected,
                label: Text(cat == 'All' ? l10n.all : cat),
                onSelected: (_) => setState(() => _selectedCategory = cat),
                avatar: selected ? const Icon(Icons.check_rounded, size: 18) : null,
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
                selectedColor: cs.primary,
                backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
              );
            },
          ),
        ),
      ),
    ];

    if (tags.isNotEmpty) {
      slivers.addAll([
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tags,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final tag in tags)
                          ChoiceChip(
                            label: Text(tag),
                            selected: _selectedTags.contains(tag),
                            onSelected: (_) {
                              setState(() {
                                if (_selectedTags.contains(tag)) {
                                  _selectedTags.remove(tag);
                                } else {
                                  _selectedTags.add(tag);
                                }
                              });
                            },
                            selectedColor: cs.secondary.withOpacity(0.18),
                            avatar: _selectedTags.contains(tag)
                                ? const Icon(Icons.check_rounded, size: 18)
                                : null,
                            backgroundColor:
                            Theme.of(context).colorScheme.surface.withOpacity(0.85),
                          ),
                        if (_selectedTags.isNotEmpty)
                          ActionChip(
                            avatar: const Icon(Icons.filter_alt_off, size: 18),
                            label: Text(l10n.clearTagFilters),
                            onPressed: () => setState(() {
                              _selectedTags.clear();
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]);
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 8)));

    if (showFavoritesOnly && !favoritesProvider.isLoaded) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (displayTools.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            title: showFavoritesOnly ? l10n.noFavoritesTitle : l10n.noToolsFoundTitle,
            subtitle:
            showFavoritesOnly ? l10n.noFavoritesSubtitle : l10n.noToolsFoundSubtitle,
          ),
        ),
      );
    } else {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final cols = _columnsForWidth(context);
              const tileHeight = 240.0;
              const gap = 14.0;

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  mainAxisExtent: tileHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                    final tool = displayTools[idx];
                    return ToolCard(
                      tool: tool,
                      onTap: () => _onToolTap(tool),
                      isFavorite: favoritesProvider.isFavorite(tool.id),
                      onFavoriteToggle: () => favoritesProvider.toggleFavorite(tool.id),
                    );
                  },
                  childCount: displayTools.length,
                ),
              );
            },
          ),
        ),
      );
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 84)));
    return slivers;
  }

  List<Widget> _buildHistorySlivers(BuildContext context, List<Tool> allTools) {
    final l10n = AppLocalizations.of(context)!;
    final history = context.watch<HistoryProvider>();
    final errorMessage = history.error;

    if (history.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.historyErrorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => history.fetchHistory(),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final activities = history.activities;
    if (activities.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            title: l10n.historyEmptyTitle,
            subtitle: l10n.historyEmptySubtitle,
          ),
        ),
      ];
    }

    final toolById = {for (final tool in allTools) tool.id: tool};
    final dateFormat = DateFormat.yMMMEd().add_jm();

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final activity = activities[index];
              final tool = toolById[activity.toolId];
              return _HistoryEntryCard(
                activity: activity,
                tool: tool,
                dateFormat: dateFormat,
                l10n: l10n,
                onTap: tool == null ? null : () => _onToolTap(tool),
              );
            },
            childCount: activities.length,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 72)),
    ];
  }

  // 1) helper: pick a good column count for the screen width
  int _columnsForWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1100) return 4;
    if (w >= 750) return 3;
    return 2;
  }
}

/// Search bar with pill look + clear button.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hint,
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Clear search',
          onPressed: onClear,
        )
            : null,
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.gradients,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final PremiumGradients? gradients;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: gradients?.heroGlow ??
            LinearGradient(
              colors: [
                cs.primary.withOpacity(0.65),
                cs.secondary.withOpacity(0.55),
              ],
            ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: gradients?.cardGradient,
              border: Border.all(color: cs.outline.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: cs.primary, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.auto_awesome, color: cs.tertiary, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Friendly empty-state widget.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradients = Theme.of(context).extension<PremiumGradients>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: gradients?.heroGlow,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome, size: 42, color: cs.onPrimary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style:
            Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

final JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

String _formatHistoryValue(dynamic value) {
  if (value == null) return '—';
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  if (value is DateTime) return DateFormat.yMMMEd().add_jm().format(value);
  if (value is List) {
    return value.map(_formatHistoryValue).join(', ');
  }
  if (value is Map) {
    try {
      return _prettyEncoder.convert(value);
    } catch (_) {
      return value.toString();
    }
  }
  return value.toString();
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.activity,
    required this.tool,
    required this.dateFormat,
    required this.l10n,
    this.onTap,
  });

  final ToolActivity activity;
  final Tool? tool;
  final DateFormat dateFormat;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final timestamp = activity.timestamp;
    final timeLabel = timestamp != null ? dateFormat.format(timestamp) : l10n.historyUnknownTime;
    final subtitle = tool?.subtitle;

    Widget buildThumbnail() {
      if (tool?.imageUrl != null && tool!.imageUrl.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            tool!.imageUrl,
            fit: BoxFit.cover,
          ),
        );
      }
      return Icon(Icons.history, color: cs.primary);
    }

    final gradients = Theme.of(context).extension<PremiumGradients>();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: gradients?.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: buildThumbnail(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool?.title ?? l10n.historyUnknownTool,
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (subtitle != null && subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                timeLabel,
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null) Icon(Icons.north_east, color: cs.onSurfaceVariant),
                  ],
                ),
                if (activity.inputs.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _HistorySection(
                    title: l10n.historyInputsLabel,
                    values: activity.inputs,
                  ),
                ],
                if (activity.outputs.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _HistorySection(
                    title: l10n.historyOutputsLabel,
                    values: activity.outputs,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.title, required this.values});

  final String title;
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...values.entries.map((entry) {
          final valueText = _formatHistoryValue(entry.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  valueText,
                  style: tt.bodyMedium,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
