import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GrokService {
  final String _apiKey = dotenv.env['GROK_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.x.ai/v1';

  Future<Map<String, dynamic>> runTool(String toolId, String model, String prompt) async {
    // Fail early if the API key is not configured to provide a clear error message.
    if (_apiKey.isEmpty) {
      throw Exception('GROK_API_KEY is not configured. Please add it to your .env file.');
    }

    final url = '$_baseUrl/chat/completions';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Extract the main text content from the AI's response.
        // This assumes a standard chat completion API response structure.
        final summary = responseBody['choices'][0]['message']['content'] ?? 'No summary was returned from the API.';

        // The client's results screen is designed for a rich, structured `AnalysisResult`.
        // Since we are now using a generic text-based AI model, we can only dynamically
        // populate the 'summary'. The other fields are given sensible default or empty
        // values to ensure the UI remains stable and does not crash.
        return {
          'result': {
            'subjectImage': 'https://images.unsplash.com/photo-1529699211952-734e80c4d42b?q=80&w=2574&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
            'spectrum': { 'minLabel': 'Liberal', 'maxLabel': 'Conservative', 'value': 0, 'confidence': 0.0 },
            'alignments': [], // Returned as empty list as it cannot be derived from a text response.
            'keywords': [],   // Returned as empty list as it cannot be derived from a text response.
            'summary': summary, // This is the dynamic content from the API.
            'meta': { 'analyzedItemsCount': 1, 'timeRange': 'N/A', 'modelUsed': model },
          }
        };
      } else {
        // Attempt to parse a more detailed error message from the API response body.
        String errorMessage = response.reasonPhrase ?? 'Unknown error';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody['error'] != null && errorBody['error']['message'] != null) {
            errorMessage = errorBody['error']['message'];
          }
        } catch (_) {
          // Ignore if the error response is not valid JSON and use the reason phrase.
        }
        throw Exception('Failed to run tool: ${response.statusCode} $errorMessage');
      }
    } catch (e) {
      // Handle network errors or other exceptions during the request.
      throw Exception('Failed to connect to the service. Please check your network connection and the API endpoint URL.');
    }
  }
}