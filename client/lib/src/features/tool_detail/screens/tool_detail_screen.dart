import 'package:flutter/material.dart';

class ToolDetailScreen extends StatelessWidget {
  final String toolId;
  const ToolDetailScreen({super.key, required this.toolId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tool: $toolId')),
      body: Center(child: Text('Tool Detail Screen for $toolId')),
    );
  }
}
