import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { isConnected, isDisconnected, isChecking }

class ConnectivityService extends StateNotifier<ConnectivityStatus> {
  ConnectivityService() : super(ConnectivityStatus.isChecking) {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> _init() async {
    try {
      final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
      _updateStatus(result);
    } catch (e) {
      debugPrint('[NET] Error checking connectivity: $e');
      state = ConnectivityStatus.isConnected; // Fallback to avoid false alarms
    }

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // connectivity_plus 6.0+ returns List<ConnectivityResult>
    if (results.contains(ConnectivityResult.none)) {
      state = ConnectivityStatus.isDisconnected;
    } else {
      state = ConnectivityStatus.isConnected;
    }
    debugPrint('[NET] Connectivity Status: $state');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityService, ConnectivityStatus>((ref) {
  return ConnectivityService();
});
