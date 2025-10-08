import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:client/providers/auth_provider.dart';
import 'package:client/providers/firestore_provider.dart';

class HistoryProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final FirestoreProvider firestoreProvider;

  HistoryProvider(this.authProvider, this.firestoreProvider) {
    _listenToAuthChanges();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<QueryDocumentSnapshot> _activities = [];
  List<QueryDocumentSnapshot> get activities => _activities;

  StreamSubscription<QuerySnapshot>? _historySubscription;

  void _listenToAuthChanges() {
    authProvider.addListener(() {
      if (authProvider.user != null) {
        fetchHistory();
      } else {
        _clearSubscription();
        _activities = [];
        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchHistory() async {
    if (authProvider.user == null) return;

    await _historySubscription?.cancel();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stream = firestoreProvider.getActivity(authProvider.user!.uid);
      _historySubscription = stream.listen((snapshot) {
        _activities = snapshot.docs;
        _isLoading = false;
        notifyListeners();
      }, onError: (Object e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearSubscription() {
    _historySubscription?.cancel();
    _historySubscription = null;
  }

  @override
  void dispose() {
    _clearSubscription();
    super.dispose();
  }
}
