// lib/admin/json_tool_uploader_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Your models
import '../models/tool.dart'; // has Tool.fromJson(Map, String id)

class JsonToolUploaderScreen extends StatefulWidget {
  const JsonToolUploaderScreen({super.key});

  @override
  State<JsonToolUploaderScreen> createState() => _JsonToolUploaderScreenState();
}

class _JsonToolUploaderScreenState extends State<JsonToolUploaderScreen> {
  final _idCtrl = TextEditingController();
  final _jsonCtrl = TextEditingController();
  String? _validationMsg;
  Tool? _parsed;
  bool _isUploading = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _jsonCtrl.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _validationMsg = null;
      _parsed = null;
    });

    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      setState(() => _validationMsg = 'Please enter a document ID (e.g., whimsical_watercolor_anime).');
      return;
    }

    Map<String, dynamic> jsonMap;
    try {
      jsonMap = jsonDecode(_jsonCtrl.text) as Map<String, dynamic>;
    } catch (e) {
      setState(() => _validationMsg = 'Invalid JSON: $e');
      return;
    }

    // Basic shape checks before model parsing (gives clearer errors)
    final requiredTop = ['title', 'subtitle', 'imageUrl'];
    for (final k in requiredTop) {
      if (!jsonMap.containsKey(k) || (jsonMap[k] is String && (jsonMap[k] as String).trim().isEmpty)) {
        setState(() => _validationMsg = 'Missing or empty required field: $k');
        return;
      }
    }

    try {
      final tool = Tool.fromJson(jsonMap, id);
      setState(() {
        _parsed = tool;
        _validationMsg = 'Looks good ✅';
      });
    } catch (e) {
      setState(() => _validationMsg = 'Failed to parse into Tool model: $e');
    }
  }

  Future<void> _upload() async {
    if (_parsed == null) {
      _validate();
      if (_parsed == null) return;
    }
    final id = _idCtrl.text.trim();
    final jsonMap = jsonDecode(_jsonCtrl.text) as Map<String, dynamic>;

    setState(() => _isUploading = true);
    try {
      await FirebaseFirestore.instance.collection('tools').doc(id).set(jsonMap);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tool uploaded to Firestore ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Tool JSON')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idCtrl,
              decoration: const InputDecoration(
                labelText: 'Document ID',
                hintText: 'e.g., whimsical_watercolor_anime',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _jsonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tool JSON',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(height: 8),
            if (_validationMsg != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _validationMsg!,
                  style: tt.bodySmall?.copyWith(
                    color: _validationMsg!.contains('✅') ? Colors.green : Colors.red,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _validate,
                  icon: const Icon(Icons.verified),
                  label: const Text('Validate'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isUploading ? null : _upload,
                  icon: _isUploading
                      ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  label: const Text('Upload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
