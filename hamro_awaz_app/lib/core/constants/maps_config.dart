/// Google Maps configuration.
///
/// Leave [apiKey] empty to use list-only map screen (avoids native crash when
/// `com.google.android.geo.API_KEY` is missing). When you have a key, set it here
/// AND in `android/local.properties` as `google.maps.api.key=YOUR_KEY`.
class MapsConfig {
  MapsConfig._();

  /// Paste your Google Maps API key here, or set via --dart-define=GOOGLE_MAPS_API_KEY=...
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get isNativeMapEnabled => apiKey.isNotEmpty;
}
