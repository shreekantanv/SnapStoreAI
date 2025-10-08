import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/tool_activity.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider();

  AuthProvider? _authProvider;
  FirestoreProvider? _firestoreProvider;
  VoidCallback? _authListener;
  bool _listeningToAuth = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final List<ToolActivity> _activities = <ToolActivity>[];
  List<ToolActivity> get activities => List.unmodifiable(_activities);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _historySubscription;
  String? _currentUid;

  void update(AuthProvider authProvider, FirestoreProvider firestoreProvider) {
    final authChanged = !identical(_authProvider, authProvider);

    if (_listeningToAuth && authChanged && _authProvider != null && _authListener != null) {
      _authProvider!.removeListener(_authListener!);
      _listeningToAuth = false;
    }

    _authProvider = authProvider;
    _firestoreProvider = firestoreProvider;

    _authListener ??= _handleAuthChanged;

    if (!_listeningToAuth && _authListener != null) {
      _authProvider!.addListener(_authListener!);
      _listeningToAuth = true;
    }

    _handleAuthChanged();
  }

  Future<void> fetchHistory() async {
    final authProvider = _authProvider;
    final firestoreProvider = _firestoreProvider;

    if (authProvider == null || firestoreProvider == null) {
      _resetState();
      return;
    }

    final uid = authProvider.user?.uid;
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
      final stream = firestoreProvider.getActivity(uid);
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
    final authProvider = _authProvider;
    if (authProvider == null) {
      return;
    }

    final uid = authProvider.user?.uid;
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
    if (_authListener != null && _authProvider != null && _listeningToAuth) {
      _authProvider!.removeListener(_authListener!);
    }
    _authListener = null;
    _listeningToAuth = false;
    _authProvider = null;
    _firestoreProvider = null;
    _clearSubscription();
    super.dispose();
  }
}
