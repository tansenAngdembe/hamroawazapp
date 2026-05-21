import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/maps_config.dart';

/// Renders [GoogleMap] only when a Maps API key is configured; otherwise a safe placeholder.
class SafeMapWidget extends StatelessWidget {
  const SafeMapWidget({
    super.key,
    required this.initialTarget,
    required this.markers,
    required this.onMapCreated,
    this.zoom = 13,
  });

  final LatLng initialTarget;
  final Set<Marker> markers;
  final void Function(GoogleMapController controller) onMapCreated;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    if (!MapsConfig.isNativeMapEnabled) {
      return _MapPlaceholder(lat: initialTarget.latitude, lng: initialTarget.longitude);
    }

    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: zoom,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: true,
      zoomControlsEnabled: false,
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Map preview',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Nearby complaints are listed below. To enable the interactive map, '
                'add your Google Maps API key to MapsConfig / AndroidManifest.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Center: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
