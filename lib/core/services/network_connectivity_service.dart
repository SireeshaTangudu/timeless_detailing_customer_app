import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  VoidCallback? onReconnected;

  NetworkConnectivityService() {
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final bool previouslyConnected = _isConnected;
    final bool currentlyConnected = !results.contains(ConnectivityResult.none) && results.isNotEmpty;

    if (_isConnected != currentlyConnected) {
      _isConnected = currentlyConnected;
      notifyListeners();

      // Trigger automatic API refresh callback when connection is restored
      if (!previouslyConnected && _isConnected) {
        debugPrint('🌐 [NetworkConnectivityService] Internet connection restored! Triggering auto-retry API calls...');
        if (onReconnected != null) {
          onReconnected!();
        }
      }
    }
  }

  Future<bool> checkConnectionNow() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error re-checking connectivity: $e');
    }
    return _isConnected;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
