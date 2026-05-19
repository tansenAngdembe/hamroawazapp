import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../features/map/data/nearby_complaints_api_service.dart';
import '../../features/map/domain/nearby_complaint_filter_status.dart';
import '../../features/map/presentation/map_view_controller.dart';
import '../../features/map/presentation/widgets/map_nearby_complaint_card.dart';
import '../../services/auth_service.dart';

/// Map + nearby complaints with filters. Uses feature-layer controller + API service.
class MapViewScreen extends StatelessWidget {
  const MapViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final api = NearbyComplaintsApiService(
          authService: context.read<AuthService>(),
        );
        final c = MapViewController(apiService: api);
        c.initialize();
        return c;
      },
      child: const _MapViewBody(),
    );
  }
}

class _MapViewBody extends StatelessWidget {
  const _MapViewBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nearby complaints'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: ctrl.isRefreshing ? null : () => ctrl.refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HorizontalFilterStrip(controller: ctrl),
              if (ctrl.locationBanner != null)
                Material(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ctrl.locationBanner!,
                            style: TextStyle(
                              color: Colors.grey.shade900,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GoogleMap(
                      onMapCreated: ctrl.onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(ctrl.userLat, ctrl.userLng),
                        zoom: 13,
                      ),
                      markers: ctrl.markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: _ComplaintsPanel(controller: ctrl),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Top horizontal strip: radius + status filters (responsive scroll on narrow widths).
class _HorizontalFilterStrip extends StatelessWidget {
  const _HorizontalFilterStrip({required this.controller});

  final MapViewController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget pill({required Widget child}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: child,
      );
    }

    return Material(
      elevation: 0.5,
      color: scheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 12),
            pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radio_button_checked, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Radius',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: controller.radiusKm,
                      borderRadius: BorderRadius.circular(12),
                      alignment: AlignmentDirectional.centerEnd,
                      items: NearbyMapRadiusOptions.values
                          .map(
                            (km) => DropdownMenuItem<double>(
                              value: km,
                              child: Text('${km.toStringAsFixed(0)} km'),
                            ),
                          )
                          .toList(),
                      onChanged: controller.isRefreshing
                          ? null
                          : (v) {
                              if (v != null) controller.setRadiusKm(v);
                            },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<NearbyComplaintFilterStatus>(
                      value: controller.statusFilter,
                      borderRadius: BorderRadius.circular(12),
                      items: NearbyComplaintFilterStatus.values
                          .map(
                            (s) => DropdownMenuItem<NearbyComplaintFilterStatus>(
                              value: s,
                              child: Text(s.displayLabel),
                            ),
                          )
                          .toList(),
                      onChanged: controller.isRefreshing
                          ? null
                          : (v) {
                              if (v != null) controller.setStatusFilter(v);
                            },
                    ),
                  ),
                ],
              ),
            ),
            if (controller.isRefreshing) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComplaintsPanel extends StatelessWidget {
  const _ComplaintsPanel({required this.controller});

  final MapViewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.isLoading &&
        controller.complaints.isEmpty &&
        controller.errorMessage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Finding complaints near you…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.errorMessage != null && controller.complaints.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: controller.isRefreshing ? null : () => controller.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text(
                'Nearby list',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${controller.complaints.length} items',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => controller.refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (controller.complaints.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_searching,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No complaints in this area',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try a larger radius or change status filter.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...controller.complaints.map(
                    (c) => MapNearbyComplaintCard(
                      complaint: c,
                      isSelected: controller.selectedUniqueId == c.uniqueId,
                      onTap: () {
                        controller.selectComplaint(c.uniqueId);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
