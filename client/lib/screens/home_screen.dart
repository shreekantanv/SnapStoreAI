import 'package:client/screens/settings_screen.dart';
import 'package:client/screens/tools/tool_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/tool_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/favorite_tools_provider.dart';
import '../widgets/tool_widget.dart';
import '../models/tool.dart';

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

    return StreamBuilder<List<Tool>>(
      stream: prov.tools,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }
        final allTools = snapshot.data ?? [];
        final categorySet = <String>{...allTools.map((t) => t.category)}
          ..removeWhere((element) => element.trim().isEmpty);
        final categories = ['All', ...categorySet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()))];
        final tags = allTools
            .expand((t) => t.tags)
            .map((e) => e.trim())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        final filtered = allTools.where((t) {
          final q = _search.trim().toLowerCase();
          final matchesSearch = q.isEmpty ||
              t.title.toLowerCase().contains(q) ||
              t.subtitle.toLowerCase().contains(q);
          final matchesCategory =
              _selectedCategory == 'All' || t.category == _selectedCategory;
          final matchesTags =
              _selectedTags.isEmpty || _selectedTags.every(t.tags.contains);
          return matchesSearch && matchesCategory && matchesTags;
        }).toList();

        final showFavoritesOnly = _currentNavIndex == 1;
        final displayTools = filtered
            .where(
              (tool) =>
                  !showFavoritesOnly || favoritesProvider.isFavorite(tool.id),
            )
            .toList();

        return Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentNavIndex,
            onTap: (i) {
              if (i == 3) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
              } else {
                setState(() => _currentNavIndex = i);
              }
            },
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.tools),
              BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: l10n.favorites),
              BottomNavigationBarItem(icon: const Icon(Icons.history), label: l10n.history),
              BottomNavigationBarItem(icon: const Icon(Icons.settings), label: l10n.settings),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                titleSpacing: 12,
                title: Row(
                  children: [
                    // app logo (optional)
                    Image.asset('assets/images/logo.png', height: 28),
                    const SizedBox(width: 8),
                    Text('SnapStoreAI', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      themeProvider.themeMode == ThemeMode.light
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    tooltip: l10n.settings,
                    onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign out',
                    onPressed: () => context.read<AuthProvider>().signOut(),
                  ),
                ],
              ),
            ],
            body: CustomScrollView(
              slivers: [
                // Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

                // Category chips
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final cat = categories[i];
                        final selected = cat == _selectedCategory;
                        return FilterChip(
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) ...[
                                const Icon(Icons.check, size: 16),
                                const SizedBox(width: 6),
                              ],
                              Text(cat == 'All' ? l10n.all : cat),
                            ],
                          ),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                          ),
                          selectedColor: cs.primary,
                          side: BorderSide(color: cs.outlineVariant),
                          backgroundColor: Theme.of(context).cardColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        );
                      },
                    ),
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.tags,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in tags)
                                FilterChip(
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
                                ),
                              if (_selectedTags.isNotEmpty)
                                InputChip(
                                  label: Text(l10n.clearTagFilters),
                                  onPressed: () => setState(() {
                                    _selectedTags.clear();
                                  }),
                                  avatar: const Icon(Icons.close, size: 18),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Grid or Empty state
                if (showFavoritesOnly && !favoritesProvider.isLoaded)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (displayTools.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      title: showFavoritesOnly
                          ? l10n.noFavoritesTitle
                          : l10n.noToolsFoundTitle,
                      subtitle: showFavoritesOnly
                          ? l10n.noFavoritesSubtitle
                          : l10n.noToolsFoundSubtitle,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final cols = _columnsForWidth(context);
                        // A tidy, uniform card height. Tweak 220–260 to taste.
                        const tileHeight = 240.0;
                        const gap = 14.0;
                        final radius = BorderRadius.circular(16);

                        return SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: gap,
                            mainAxisSpacing: gap,
                            mainAxisExtent: tileHeight, // <- keeps rows perfectly aligned
                          ),
                          delegate: SliverChildBuilderDelegate(
                                (context, idx) {
                              final tool = displayTools[idx];
                              return ClipRRect(
                                borderRadius: radius, // ensures overlay/tile share same rounding
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Your visual card
                                    ToolCard(
                                      tool: tool,
                                      isFavorite: favoritesProvider.isFavorite(tool.id),
                                      onFavoriteToggle: () =>
                                          favoritesProvider.toggleFavorite(tool.id),
                                    ),

                                    // Full-tile tap layer
                                    Material(
                                      type: MaterialType.transparency,
                                      child: InkWell(
                                        onTap: () => _onToolTap(tool),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: displayTools.length,
                          ),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 84)), // bottom padding
              ],
            ),
          ),
        );
      },
    );
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear',
              onPressed: onClear,
            ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: cs.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
