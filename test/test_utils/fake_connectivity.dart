import 'package:connectivity_plus/connectivity_plus.dart';

/// A simple fake for [Connectivity] used in tests.
class FakeConnectivity extends Connectivity {
  @override
  Future<ConnectivityResult> checkConnectivity() async {
    return ConnectivityResult.wifi;
  }

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => const Stream.empty();
}
