import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  bool _loading = false;
  List<dynamic> _employees = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  LatLng get _initialCenter {
    if (_employees.isNotEmpty) {
      final e = _employees.first;
      final lat = (e['latitude'] as num?)?.toDouble();
      final lng = (e['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return const LatLng(32.3325, 35.7523);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _employees = await ApiService.getLiveEmployees();
    } catch (e) {
      _snack('تعذر تحميل المواقع الحية: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التتبع الحي للموظفين'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: _initialCenter, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.yarmouk.water',
                ),
                MarkerLayer(
                  markers: _employees.map((e) {
                    final lat = (e['latitude'] as num?)?.toDouble() ?? 0;
                    final lng = (e['longitude'] as num?)?.toDouble() ?? 0;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 40,
                      height: 40,
                      child: Tooltip(
                        message: e['full_name'] ?? 'موظف #${e['employee_id']}',
                        child: const Icon(Icons.person_pin_circle,
                            color: AppTheme.primaryColor, size: 36),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
