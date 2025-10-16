import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (_) {}

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
