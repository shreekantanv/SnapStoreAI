import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/tool.dart';
import '../providers/tool_provider.dart';
import '../widgets/category_widget.dart';
import '../widgets/tool_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ToolProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(context)!;

    // early loading / error states
    if (prov.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (prov.error != null) {
      return Scaffold(
        body: Center(child: Text('Error: ${prov.error}')),
      );
    }

    // build list of categories including "All"
    final categories = <String>['All', ...prov.groupedByCategory.keys];

    // filter tools by search & category
    List<Tool> filtered = prov.allTools.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_search);
      final matchesCategory =
          _selectedCategory == 'All' || t.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1) Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for tools',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
              ),
            ),

            // 2) Horizontal category chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  final selected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 3) Grid of tool cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  itemCount: filtered.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3 / 4,
                  ),
                  itemBuilder: (context, idx) {
                    final tool = filtered[idx];
                    return ToolCard(tool: tool);
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // 4) Floating wallet button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to wallet
        },
        child: const Icon(Icons.account_balance_wallet),
      ),

      // 5) Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
        type: BottomNavigationBarType.fixed, // Ensure visibility
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.tools,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: l10n.favorites,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: l10n.history,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: l10n.wallet,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
