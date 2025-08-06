import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider for the SharedSession.
///
/// This holds in-memory state that might be shared across different screens
/// during a single user session, such as the inputs and outputs of a tool run.
/// This allows data to be passed between the ToolDetailScreen and the ResultScreen
/// without persisting it or passing it as complex route arguments.
final sharedSessionProvider =
    ChangeNotifierProvider((ref) => SharedSession());

/// In-memory storage for a single tool-running session.
class SharedSession with ChangeNotifier {
  /// Stores the user's inputs for the tool.
  /// The key is the field name (from JSON), and the value is the user's input.
  final Map<String, dynamic> _inputs = {};
  Map<String, dynamic> get inputs => _inputs;

  /// Stores the outputs from the AI model.
  /// The key could be 'result', 'error', etc.
  final Map<String, dynamic> _outputs = {};
  Map<String, dynamic> get outputs => _outputs;

  /// Updates an input value and notifies listeners.
  void setInput(String key, dynamic value) {
    _inputs[key] = value;
    notifyListeners();
  }

  /// Updates an output value and notifies listeners.
  void setOutput(String key, dynamic value) {
    _outputs[key] = value;
    notifyListeners();
  }

  /// Clears all session data. This should be called after a tool run is
  /// complete and the user navigates away from the result.
  void clear() {
    _inputs.clear();
    _outputs.clear();
    notifyListeners();
  }
}
