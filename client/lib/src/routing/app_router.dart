import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_tool_store_client/src/features/home/screens/tool_store_screen.dart';
import 'package:ai_tool_store_client/src/features/tool_detail/screens/tool_detail_screen.dart';
import 'package:ai_tool_store_client/src/features/tool_runner/screens/result_screen.dart';
import 'package:ai_tool_store_client/src/features/wallet/screens/wallet_screen.dart';
import 'package:ai_tool_store_client/src/features/purchase/screens/purchase_flow_screen.dart';
import 'package:ai_tool_store_client/src/features/settings/screens/settings_screen.dart';

// Provider for the GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const ToolStoreScreen(),
      ),
      GoRoute(
        path: '/tool/:id',
        name: 'toolDetail',
        builder: (context, state) {
          final toolId = state.pathParameters['id']!;
          return ToolDetailScreen(toolId: toolId);
        },
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: '/wallet',
        name: 'wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/purchase',
        name: 'purchase',
        builder: (context, state) => const PurchaseFlowScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    // Optional: Add error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
