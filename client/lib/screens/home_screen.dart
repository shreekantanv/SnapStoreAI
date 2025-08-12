import 'package:client/screens/tools/political_leaning_analyzer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/tool_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
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
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onToolTap(Tool tool) {
    // Prefer routing by stable tool.id
    final id = (tool.id ?? '').trim();
    debugPrint('Tapped tool -> id=${id}, title=${tool.title}');
    switch (id) {
      case 'IRVPDzBQqV5qVFLJYheU':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PoliticalLeaningEntryScreen()),
        );
        return;
    }

    // Default (optional)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ToolProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (prov.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (prov.error != null) {
      return Scaffold(body: Center(child: Text('Error: ${prov.error}')));
    }

    final categories = <String>['All', ...prov.groupedByCategory.keys];

    final filtered = prov.allTools.where((t) {
      final q = _search.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.subtitle.toLowerCase().contains(q);
      final matchesCategory =
          _selectedCategory == 'All' || t.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to wallet
        },
        child: const Icon(Icons.account_balance_wallet),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.tools),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: l10n.favorites),
          BottomNavigationBarItem(icon: const Icon(Icons.history), label: l10n.history),
          BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet), label: l10n.wallet),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: l10n.settings),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: prov.refresh,
        child: NestedScrollView(
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
                            Text(cat),
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
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Grid or Empty state
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: const _EmptyState(
                    title: 'No tools found',
                    subtitle: 'Try a different keyword or category.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, idx) {
                        final tool = filtered[idx];
                        return Stack(
                          children: [
                            // your existing visual card
                            ToolCard(tool: tool),

                            // full-tile tap layer (always receives taps)
                            Positioned.fill(
                              child: Material(
                                type: MaterialType.transparency, // needed for InkWell
                                child: InkWell(
                                  onTap: () => _onToolTap(tool),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 84)), // bottom padding
            ],
          ),
        ),
      ),
    );
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
