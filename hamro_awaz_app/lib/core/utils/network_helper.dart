import 'dart:io';
import 'package:http/http.dart' as http;
import 'debug_helper.dart';

class NetworkHelper {
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> checkServerReachability(String baseUrl) async {
    try {
      DebugHelper.log('Checking server reachability', baseUrl);
      
      final uri = Uri.parse(baseUrl);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      DebugHelper.log('Server reachability check result', {
        'statusCode': response.statusCode,
        'body': response.body,
      });

      return {
        'reachable': true,
        'statusCode': response.statusCode,
        'body': response.body,
      };
    } on SocketException catch (e) {
      DebugHelper.logError('Socket exception during server check', e);
      return {
        'reachable': false,
        'error': 'Cannot reach server: ${e.message}',
      };
    } on http.ClientException catch (e) {
      DebugHelper.logError('HTTP client exception during server check', e);
      return {
        'reachable': false,
        'error': 'HTTP error: ${e.message}',
      };
    } catch (e) {
      DebugHelper.logError('Unexpected error during server check', e);
      return {
        'reachable': false,
        'error': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> performNetworkDiagnostics(String baseUrl) async {
    final diagnostics = <String, dynamic>{};

    // Check internet connectivity
    diagnostics['hasInternet'] = await hasInternetConnection();

    // Check server reachability
    final serverCheck = await checkServerReachability(baseUrl);
    diagnostics['serverReachable'] = serverCheck['reachable'];
    diagnostics['serverResponse'] = serverCheck;

    // Additional checks
    diagnostics['baseUrl'] = baseUrl;
    diagnostics['timestamp'] = DateTime.now().toIso8601String();

    DebugHelper.log('Network diagnostics completed', diagnostics);

    return diagnostics;
  }
}