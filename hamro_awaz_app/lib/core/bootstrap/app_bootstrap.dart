import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/debug_helper.dart';

/// Runs before [runApp]. Must be called after [WidgetsFlutterBinding.ensureInitialized].
class AppBootstrap {
  static Future<void> initialize() async {
    _installErrorHandlers();

    try {
      // Warm up SharedPreferences so first login/splash read does not race plugins.
      await SharedPreferences.getInstance();
      DebugHelper.log('AppBootstrap: SharedPreferences ready');
    } catch (e, st) {
      DebugHelper.logError('AppBootstrap: SharedPreferences init failed (non-fatal)', e, st);
    }
  }

  static void _installErrorHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      DebugHelper.logError(
        'FlutterError: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      DebugHelper.logError('Uncaught async error', error, stack);
      return true;
    };
  }
}

/// Catches async errors that escape [Future]s in widgets.
void runAppGuarded(Widget app) {
  runZonedGuarded(
    () => runApp(app),
    (error, stack) {
      DebugHelper.logError('runZonedGuarded', error, stack);
    },
  );
}
