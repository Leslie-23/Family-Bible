import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  bool onlineFrom(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  yield onlineFrom(await connectivity.checkConnectivity());

  await for (final results in connectivity.onConnectivityChanged) {
    yield onlineFrom(results);
  }
});
