import 'dart:async' show TimeoutException;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants/api_constants.dart';
import '../core/utils/debug_helper.dart';
import '../models/create_complaint_request.dart';

class LocationResult {
  const LocationResult({
    required this.coordinates,
    this.warning,
  });

  final ComplaintCoordinates coordinates;
  final String? warning;
}

class LocationService {
  Future<LocationResult> resolveComplaintCoordinates({
    int maxRetries = 2,
  }) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final granted = await _ensureLocationPermission();
        if (!granted) {
          return LocationResult(
            coordinates: const ComplaintCoordinates(
              latitude: ApiConstants.defaultLatitude,
              longitude: ApiConstants.defaultLongitude,
            ),
            warning:
                'Location permission denied. Using default coordinates. Enable GPS in Settings for accuracy.',
          );
        }

        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) {
          return LocationResult(
            coordinates: const ComplaintCoordinates(
              latitude: ApiConstants.defaultLatitude,
              longitude: ApiConstants.defaultLongitude,
            ),
            warning: 'Location services are disabled. Using default map center.',
          );
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );

        return LocationResult(
          coordinates: ComplaintCoordinates(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      } on TimeoutException catch (e) {
        DebugHelper.logError('Location timeout attempt $attempt', e);
        if (attempt == maxRetries) {
          return _fallback('Location timed out. Using default coordinates.');
        }
      } catch (e, st) {
        DebugHelper.logError('Location error attempt $attempt', e, st);
        if (attempt == maxRetries) {
          return _fallback('Unable to read GPS (${e.toString()}). Using default coordinates.');
        }
      }
      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }
    return _fallback('Location unavailable.');
  }

  LocationResult _fallback(String warning) {
    return LocationResult(
      coordinates: const ComplaintCoordinates(
        latitude: ApiConstants.defaultLatitude,
        longitude: ApiConstants.defaultLongitude,
      ),
      warning: warning,
    );
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      final status = await Permission.location.request();
      return status.isGranted;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
