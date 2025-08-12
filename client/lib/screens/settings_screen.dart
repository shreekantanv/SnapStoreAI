import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _grokApiKeyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _storage.read(key: 'grok_api_key');
    if (apiKey != null) {
      _grokApiKeyCtrl.text = apiKey;
    }
  }

  Future<void> _saveApiKey() async {
    await _storage.write(key: 'grok_api_key', value: _grokApiKeyCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Premium Features',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _grokApiKeyCtrl,
            decoration: const InputDecoration(
              labelText: 'Grok API Key',
              hintText: 'Enter your Grok API key',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveApiKey,
            child: const Text('Save API Key'),
          ),
        ],
      ),
    );
  }
}
