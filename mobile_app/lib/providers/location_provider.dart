import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/work_zone_model.dart';
import '../services/location_service.dart';
import '../services/geofence_service.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();
  @override
  List<Object?> get props => [];
}

class LocationStartTracking extends LocationEvent {
  final int employeeId;
  const LocationStartTracking(this.employeeId);
  @override
  List<Object?> get props => [employeeId];
}

class LocationStopTracking extends LocationEvent {}

class LocationUpdateReceived extends LocationEvent {
  final Position position;
  const LocationUpdateReceived(this.position);
  @override
  List<Object?> get props => [position];
}

class LocationCheckGeofence extends LocationEvent {
  final Position position;
  final List<WorkZone> zones;
  const LocationCheckGeofence(this.position, this.zones);
  @override
  List<Object?> get props => [position, zones];
}

abstract class LocationState extends Equatable {
  const LocationState();
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationTracking extends LocationState {
  final Position currentPosition;
  final bool isInsideGeofence;
  final double? distanceToGeofence;
  final List<WorkZone> activeZones;
  final bool isMockLocation;
  final double? accuracy;
  final List<LatLng> pathPoints;

  const LocationTracking({
    required this.currentPosition,
    required this.isInsideGeofence,
    this.distanceToGeofence,
    required this.activeZones,
    this.isMockLocation = false,
    this.accuracy,
    this.pathPoints = const [],
  });

  @override
  List<Object?> get props => [
    currentPosition,
    isInsideGeofence,
    distanceToGeofence,
    activeZones,
    isMockLocation,
    accuracy,
    pathPoints,
  ];
}

class LocationError extends LocationState {
  final String message;
  const LocationError(this.message);
  @override
  List<Object?> get props => [message];
}

class LocationNotTracking extends LocationState {}

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationService _locationService = LocationService();
  final GeofenceService _geofenceService = GeofenceService();
  List<LatLng> _pathPoints = [];

  LocationBloc() : super(LocationInitial()) {
    on<LocationStartTracking>(_onStartTracking);
    on<LocationStopTracking>(_onStopTracking);
    on<LocationUpdateReceived>(_onUpdateReceived);
    on<LocationCheckGeofence>(_onCheckGeofence);
  }

  Future<void> _onStartTracking(
    LocationStartTracking event,
    Emitter<LocationState> emit,
  ) async {
    _pathPoints = [];
    emit(LocationLoading());
    try {
      await _locationService.startTracking(
        employeeId: event.employeeId,
        onLocationUpdate: (position) {
          add(LocationUpdateReceived(position));
        },
      );
    } catch (e) {
      emit(LocationError('فشل بدء التتبع: $e'));
    }
  }

  Future<void> _onStopTracking(
    LocationStopTracking event,
    Emitter<LocationState> emit,
  ) async {
    await _locationService.stopTracking();
    emit(LocationNotTracking());
  }

  void _onUpdateReceived(
    LocationUpdateReceived event,
    Emitter<LocationState> emit,
  ) {
    final position = event.position;
    final isMock = position.isMocked ?? false;
    final point = LatLng(position.latitude, position.longitude);
    if (_pathPoints.isEmpty ||
        _pathPoints.last.latitude != point.latitude ||
        _pathPoints.last.longitude != point.longitude) {
      _pathPoints.add(point);
    }

    if (state is LocationTracking) {
      final currentState = state as LocationTracking;
      emit(LocationTracking(
        currentPosition: position,
        isInsideGeofence: currentState.isInsideGeofence,
        distanceToGeofence: currentState.distanceToGeofence,
        activeZones: currentState.activeZones,
        isMockLocation: isMock,
        accuracy: position.accuracy,
        pathPoints: List.from(_pathPoints),
      ));
    } else {
      emit(LocationTracking(
        currentPosition: position,
        isInsideGeofence: false,
        activeZones: const [],
        isMockLocation: isMock,
        accuracy: position.accuracy,
        pathPoints: List.from(_pathPoints),
      ));
    }
  }

  void _onCheckGeofence(
    LocationCheckGeofence event,
    Emitter<LocationState> emit,
  ) {
    final position = event.position;
    final zones = event.zones;

    bool isInsideAny = false;
    double? minDistance;

    for (final zone in zones) {
      final inside = _geofenceService.isInsideZone(position, zone);
      final distance = _geofenceService.distanceToZone(position, zone);

      if (inside) {
        isInsideAny = true;
      }
      if (minDistance == null || (distance != null && distance < minDistance)) {
        minDistance = distance;
      }
    }

    emit(LocationTracking(
      currentPosition: position,
      isInsideGeofence: isInsideAny,
      distanceToGeofence: minDistance,
      activeZones: zones,
      isMockLocation: position.isMocked ?? false,
      accuracy: position.accuracy,
      pathPoints: List.from(_pathPoints),
    ));
  }
}
