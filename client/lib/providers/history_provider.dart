import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/tool_activity.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(AuthProvider authProvider, FirestoreProvider firestoreProvider) {
    _authProvider = authProvider;
    _firestoreProvider = firestoreProvider;
    _authListener = _handleAuthChanged;
    _authProvider.addListener(_authListener!);
    _handleAuthChanged();
  }

  late AuthProvider _authProvider;
  late FirestoreProvider _firestoreProvider;
  VoidCallback? _authListener;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final List<ToolActivity> _activities = <ToolActivity>[];
  List<ToolActivity> get activities => List.unmodifiable(_activities);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _historySubscription;
  String? _currentUid;

  void update(AuthProvider authProvider, FirestoreProvider firestoreProvider) {
    if (!identical(_authProvider, authProvider)) {
      _authProvider.removeListener(_authListener!);
      _authProvider = authProvider;
      _authProvider.addListener(_authListener!);
    }
    _firestoreProvider = firestoreProvider;
    _handleAuthChanged();
  }

  Future<void> fetchHistory() async {
    final uid = _authProvider.user?.uid;
    if (uid == null) {
      _resetState();
      return;
    }

    _currentUid = uid;
    await _historySubscription?.cancel();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stream = _firestoreProvider.getActivity(uid);
      _historySubscription = stream.listen(
        (snapshot) {
          final items = snapshot.docs
              .map(ToolActivity.fromSnapshot)
              .whereType<ToolActivity>()
              .toList(growable: false);
          _activities
            ..clear()
            ..addAll(items);
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (Object e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleAuthChanged() {
    final uid = _authProvider.user?.uid;
    if (uid == null) {
      _currentUid = null;
      _resetState();
      return;
    }

    if (_currentUid == uid && _historySubscription != null) {
      return;
    }

    _currentUid = uid;
    fetchHistory();
  }

  void _resetState() {
    _clearSubscription();
    _activities.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void _clearSubscription() {
    _historySubscription?.cancel();
    _historySubscription = null;
  }

  @override
  void dispose() {
    if (_authListener != null) {
      _authProvider.removeListener(_authListener!);
      _authListener = null;
    }
    _clearSubscription();
    super.dispose();
  }
}
