import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'debug_helper.dart';

class NetworkHelper {
  /// Quick TCP check — fails in ~8s if host/port is unreachable.
  static Future<bool> canReachServer({
    String? baseUrl,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final uri = Uri.parse(baseUrl ?? ApiConstants.baseUrl);
      final host = uri.host;
      final port = uri.port == 0 ? 9080 : uri.port;

      DebugHelper.log('TCP reachability check', {'host': host, 'port': port});

      final socket = await Socket.connect(host, port, timeout: timeout);
      await socket.close();
      DebugHelper.log('TCP reachability: OK');
      return true;
    } on SocketException catch (e) {
      DebugHelper.logError('TCP reachability failed', e);
      return false;
    } on TimeoutException catch (e) {
      DebugHelper.logError('TCP reachability timeout', e);
      return false;
    } catch (e) {
      DebugHelper.logError('TCP reachability error', e);
      return false;
    }
  }

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  static String unreachableMessage() {
    return 'Cannot connect to ${ApiConstants.baseUrl}.\n\n'
        '• Phone and PC must be on the same Wi‑Fi\n'
        '• Backend must listen on 0.0.0.0:9080 (not only localhost)\n'
        '• Windows Firewall: allow port 9080\n'
        '• Update IP in lib/core/constants/api_constants.dart\n'
        '• Android emulator: use http://10.0.2.2:9080/api/v1';
  }
}
