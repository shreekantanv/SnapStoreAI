import 'package:flutter/material.dart';

class ToolStoreScreen extends StatelessWidget {
  const ToolStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Tool Store')),
      body: const Center(child: Text('Tool Store Screen')),
    );
  }
}
