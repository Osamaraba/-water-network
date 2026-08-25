import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'live_tracking_screen.dart';
import 'zones_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final canLive = authState is AuthAuthenticated &&
        RoleConstants.hasPermission(authState.employee.roleId, 'gps.view_live');
    final canZones = authState is AuthAuthenticated &&
        (RoleConstants.hasPermission(authState.employee.roleId, 'zone.view') ||
            RoleConstants.hasPermission(authState.employee.roleId, 'zone.create'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخريطة'),
        actions: [
          if (canLive)
            IconButton(
              icon: const Icon(Icons.people_alt),
              tooltip: 'التتبع الحي',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveTrackingScreen()),
              ),
            ),
          if (canZones)
            IconButton(
              icon: const Icon(Icons.map),
              tooltip: 'المناطق',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ZonesScreen()),
              ),
            ),
        ],
      ),
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          LatLng? currentLocation;
          bool isInsideGeofence = false;
          double? accuracy;

          if (state is LocationTracking) {
            currentLocation = LatLng(
              state.currentPosition.latitude,
              state.currentPosition.longitude,
            );
            isInsideGeofence = state.isInsideGeofence;
            accuracy = state.accuracy;
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentLocation ?? const LatLng(32.3325, 35.7523),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.yarmouk.water',
                  ),
                  if (currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isInsideGeofence
                                  ? AppTheme.successColor.withOpacity(0.3)
                                  : AppTheme.dangerColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isInsideGeofence ? AppTheme.successColor : AppTheme.dangerColor,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              Icons.my_location,
                              color: isInsideGeofence ? AppTheme.successColor : AppTheme.dangerColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Geofence circle
                  if (currentLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: currentLocation,
                          radius: 50, // meters
                          useRadiusInMeter: true,
                          color: isInsideGeofence
                              ? AppTheme.successColor.withOpacity(0.1)
                              : AppTheme.dangerColor.withOpacity(0.1),
                          borderColor: isInsideGeofence ? AppTheme.successColor : AppTheme.dangerColor,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  // Tracked route (from check-in to end of duty, sampled every 50m)
                  if (state is LocationTracking && state.pathPoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: state.pathPoints,
                          strokeWidth: 4,
                          color: AppTheme.primaryColor,
                          borderColor: AppTheme.primaryColor.withOpacity(0.3),
                          borderStrokeWidth: 8,
                        ),
                      ],
                    ),
                ],
              ),
              // Location info card
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: isInsideGeofence ? AppTheme.successColor : AppTheme.dangerColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isInsideGeofence
                                    ? 'داخل المنطقة المصرح بها'
                                    : 'خارج المنطقة المصرح بها',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isInsideGeofence ? AppTheme.successColor : AppTheme.dangerColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (currentLocation != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${currentLocation.latitude.toStringAsFixed(6)}°N, ${currentLocation.longitude.toStringAsFixed(6)}°E',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                        if (accuracy != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'الدقة: ${accuracy.toStringAsFixed(1)} متر',
                            style: TextStyle(
                              fontSize: 12,
                              color: accuracy <= 15 ? AppTheme.successColor : AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Center on location button
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  onPressed: () {
                    if (currentLocation != null) {
                      _mapController.move(currentLocation, 16);
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
