import 'dart:convert';
import 'dart:typed_data';

import 'package:client/models/ai_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class GhibliStyleResult {
  final Uint8List imageBytes;
  final String mimeType;

  const GhibliStyleResult({required this.imageBytes, required this.mimeType});
}

class GhibliStyleService {
  GhibliStyleService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<GhibliStyleResult> stylize({
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
        throw UnsupportedError(
          'Provider ${provider.displayName} is not yet supported for this tool.',
        );
    }
  }

  Future<GhibliStyleResult> _runOpenAiEdit({
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

    return GhibliStyleResult(
      imageBytes: base64Decode(base64Image),
      mimeType: 'image/png',
    );
  }

  String _extensionFromMime(String mime) {
    if (mime.endsWith('png')) return 'png';
    if (mime.endsWith('jpeg') || mime.endsWith('jpg')) return 'jpg';
    return 'png';
  }

  void dispose() {
    _httpClient.close();
  }
}
