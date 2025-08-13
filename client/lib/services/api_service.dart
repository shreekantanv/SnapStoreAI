import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = 'https://us-central1-snapsolveai-b74fc.cloudfunctions.net/api';

  Future<Map<String, dynamic>> runTool(String toolId, String model, String prompt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final idToken = await user.getIdToken();
    final url = '$_baseUrl/runTool';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'toolId': toolId,
        'model': model,
        'prompt': prompt,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to run tool: ${response.reasonPhrase}');
    }
  }
}
