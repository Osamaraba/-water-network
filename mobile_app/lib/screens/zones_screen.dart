import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../models/zone_model.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  bool _loading = false;
  List<dynamic> _zones = [];
  List<dynamic> _myZones = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _zones = await ApiService.getZones();
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _myZones = await ApiService.getEmployeeZones(authState.employee.employeeId);
      }
    } catch (e) {
      _snack('تعذر تحميل المناطق: $e');
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
      appBar: AppBar(title: const Text('المناطق')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_myZones.isNotEmpty) ...[
                    const Text('مناطقي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._myZones.map((z) => _zoneCard(Zone.fromJson(z))),
                    const SizedBox(height: 16),
                  ],
                  const Text('كل المناطق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._zones.map((z) => _zoneCard(Zone.fromJson(z))),
                  if (_zones.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد مناطق'))),
                ],
              ),
            ),
    );
  }

  Widget _zoneCard(Zone z) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.map, color: AppTheme.primaryColor),
        title: Text(z.zoneName),
        subtitle: Text('النوع: ${z.zoneType}${z.description != null ? ' • ${z.description}' : ''}'),
        trailing: z.isActive ? const Text('نشطة') : const Text('غير نشطة'),
      ),
    );
  }
}
