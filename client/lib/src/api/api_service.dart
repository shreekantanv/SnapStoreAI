import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the ApiService.
final apiServiceProvider = Provider<ApiService>((ref) {
  // We can read other providers to get dependencies, like the Firebase Auth instance.
  final firebaseAuth = FirebaseAuth.instance;
  return ApiService(firebaseAuth);
});

/// A service for making authenticated API calls to the backend Cloud Functions.
class ApiService {
  final FirebaseAuth _auth;
  late final Dio _dio;

  // The base URL of your deployed Cloud Functions.
  // For local testing with the emulator, this would be something like:
  // 'http://127.0.0.1:5001/your-project-id/us-central1/api'
  // For production, it will be the URL provided by Firebase.
  final String _baseUrl = 'https://api.your-cloud-functions-url.net';

  ApiService(this._auth) {
    _dio = Dio(BaseOptions(baseUrl: _baseUrl));

    // Add an interceptor to automatically add the Firebase ID token to every request.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get the current user's ID token.
        final token = await _auth.currentUser?.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options); // Continue with the request
      },
      onError: (DioException e, handler) {
        // You can add custom error handling here.
        print('API Error: ${e.response?.statusCode} - ${e.response?.data}');
        return handler.next(e); // Continue with the error
      },
    ));
  }

  /// Calls the `/runTool` endpoint on the backend.
  ///
  /// This sends the tool details and prompt to the backend, which will
  /// handle the credit debit and the call to the third-party AI model.
  Future<Map<String, dynamic>> runTool({
    required String toolId,
    required String model,
    required String prompt,
  }) async {
    try {
      final response = await _dio.post(
        '/runTool',
        data: {
          'toolId': toolId,
          'model': model,
          'prompt': prompt,
        },
      );
      return response.data;
    } on DioException catch (e) {
      // Return the error response from the server if available.
      if (e.response != null) {
        return {
          'error': e.response?.data ?? 'An unknown API error occurred.'
        };
      }
      // Otherwise, rethrow the exception.
      rethrow;
    }
  }
}
