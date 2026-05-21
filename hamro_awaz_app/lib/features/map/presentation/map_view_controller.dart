import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../data/nearby_complaints_api_service.dart';
import '../data/models/nearby_complaint_models.dart';
import '../domain/nearby_complaint_filter_status.dart';

/// Coordinates UI, location resolution, and nearby complaints fetching for the map feature.
class MapViewController extends ChangeNotifier {
  MapViewController({required NearbyComplaintsApiService apiService})
      : _api = apiService;

  final NearbyComplaintsApiService _api;

  GoogleMapController? _mapController;
  bool _didInitialize = false;

  double _userLat = ApiConstants.defaultLatitude;
  double _userLng = ApiConstants.defaultLongitude;

  double _radiusKm = NearbyMapRadiusOptions.defaultKm;
  NearbyComplaintFilterStatus _statusFilter = NearbyComplaintFilterStatus.newComplaint;

  List<NearbyComplaintDto> _complaints = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _locationBanner;
  String? _selectedUniqueId;

  double get userLat => _userLat;
  double get userLng => _userLng;
  double get radiusKm => _radiusKm;
  NearbyComplaintFilterStatus get statusFilter => _statusFilter;
  List<NearbyComplaintDto> get complaints => List.unmodifiable(_complaints);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  String? get locationBanner => _locationBanner;
  String? get selectedUniqueId => _selectedUniqueId;

  /// Google Map markers for complaints that include coordinates.
  Set<Marker> get markers {
    final out = <Marker>{};
    for (final c in _complaints) {
      final lat = c.latitude;
      final lng = c.longitude;
      if (lat == null || lng == null) continue;
      out.add(
        Marker(
          markerId: MarkerId('complaint_${c.uniqueId}'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: c.complaintTitle,
            snippet: c.status.name,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () => selectComplaint(c.uniqueId),
        ),
      );
    }
    return out;
  }

  void selectComplaint(String? uniqueId) {
    if (_selectedUniqueId == uniqueId) return;
    _selectedUniqueId = uniqueId;
    notifyListeners();
  }

  /// Called once when the map tab is first opened: GPS → first fetch → camera.
  Future<void> initialize() async {
    if (_didInitialize) return;
    _didInitialize = true;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _resolveUserLocation();
      notifyListeners();
      await _fetchNearbyInternal(isPullRefresh: false);
      await _syncCameraToUser();
    } catch (e) {
      _didInitialize = false;
      _errorMessage = 'Could not load map data. Pull to retry.';
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh / manual reload.
  Future<void> refresh() async {
    await _fetchNearbyInternal(isPullRefresh: true);
    await _syncCameraToUser();
  }

  void setRadiusKm(double value) {
    if (_radiusKm == value) return;
    _radiusKm = value;
    notifyListeners();
    unawaited(_fetchNearbyInternal(isPullRefresh: false));
  }

  void setStatusFilter(NearbyComplaintFilterStatus value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    notifyListeners();
    unawaited(_fetchNearbyInternal(isPullRefresh: false));
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    unawaited(_syncCameraToUser());
  }

  Future<void> _syncCameraToUser() async {
    final c = _mapController;
    if (c == null) return;
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userLat, _userLng),
          14,
        ),
      );
    } catch (_) {
      // Map may not be ready yet; ignore.
    }
  }

  Future<void> _resolveUserLocation() async {
    _locationBanner = null;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _applyFallbackLocation(
          'Location services are off. Showing default area; enable GPS for accurate nearby results.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _applyFallbackLocation(
          'Location permission is permanently denied. Enable it in Settings for GPS accuracy.',
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        _applyFallbackLocation(
          'Location permission denied. Using default map center for nearby search.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _userLat = position.latitude;
      _userLng = position.longitude;
    } catch (e) {
      _applyFallbackLocation(
        'Unable to read current location (${e.toString()}). Using default center.',
      );
    }
  }

  void _applyFallbackLocation(String banner) {
    _userLat = ApiConstants.defaultLatitude;
    _userLng = ApiConstants.defaultLongitude;
    _locationBanner = banner;
  }

  Future<void> _fetchNearbyInternal({required bool isPullRefresh}) async {
    if (isPullRefresh) {
      _isRefreshing = true;
    } else if (!_isLoading) {
      // Radius/status change after initial load — use refresh indicator, not full-screen lock.
      _isRefreshing = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.fetchNearbyComplaints(
        latitude: _userLat,
        longitude: _userLng,
        radiusKm: _radiusKm,
        statusFilter: _statusFilter,
      );
      _complaints = result.complaints;
    } on NearbyComplaintsApiException catch (e) {
      _complaints = [];
      _errorMessage = e.message;
    } catch (e) {
      _complaints = [];
      _errorMessage = e.toString();
    } finally {
      _isRefreshing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
