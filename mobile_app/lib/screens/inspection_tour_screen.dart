import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../models/employee_model.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../models/inspection_tour_model.dart';

class InspectionTourScreen extends StatefulWidget {
  const InspectionTourScreen({super.key});

  @override
  State<InspectionTourScreen> createState() => _InspectionTourScreenState();
}

class _InspectionTourScreenState extends State<InspectionTourScreen> {
  bool _loading = false;
  List<dynamic> _tours = [];
  int? _roleId;
  int? _employeeId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _tours = await ApiService.getInspections();
    } catch (e) {
      _snack('تعذر تحميل الجولات: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _start(int tourId) async {
    try {
      await ApiService.startInspection(tourId);
      _snack('بدأت الجولة');
      await _load();
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  Future<void> _addPoint(int tourId) async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      await ApiService.addInspectionPoint(tourId, pos.latitude, pos.longitude);
      _snack('أُضيفت نقطة للمسار');
    } catch (e) {
      _snack('تعذر تحديد الموقع: $e');
    }
  }

  Future<void> _complete(int tourId) async {
    try {
      await ApiService.completeInspection(tourId);
      _snack('انتهت الجولة');
      await _load();
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  Future<void> _send(int tourId) async {
    try {
      await ApiService.sendInspection(tourId);
      _snack('أُرسلت الجولة إلى المدير');
      await _load();
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  Future<void> _viewPath(InspectionTour tour) async {
    try {
      final points = await ApiService.getInspectionPoints(tour.tourId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tour.title ?? 'مسار الجولة #${tour.tourId}'),
          content: SizedBox(
            width: double.maxFinite,
            child: points.isEmpty
                ? const Text('لا توجد نقاط مسار بعد')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: points.length,
                    itemBuilder: (_, i) {
                      final p = points[i];
                      return ListTile(
                        leading: const Icon(Icons.place),
                        title: Text('${p['latitude']}, ${p['longitude']}'),
                        subtitle: Text(p['recorded_at'] ?? ''),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (e) {
      _snack('تعذر تحميل المسار: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          _roleId = state.employee.roleId;
          _employeeId = state.employee.employeeId;
        }
        final isDistributor = _roleId == 12;
        return Scaffold(
          appBar: AppBar(title: const Text('جولات التفتيش')),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (isDistributor)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'الجولات المسندة إليك — ابدأ الجولة ثم أضف نقاط مسارك وأرسلها للمدير.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ..._tours.map((t) => _tourCard(InspectionTour.fromJson(t), isDistributor)),
                      if (_tours.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('لا توجد جولات'),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _tourCard(InspectionTour tour, bool isDistributor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tour.title ?? 'جولة #${tour.tourId}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('الحالة: ${_statusLabel(tour.status)}'),
            if (tour.notes != null && tour.notes!.isNotEmpty)
              Text('ملاحظات: ${tour.notes}'),
            const SizedBox(height: 10),
            if (isDistributor) ...[
              if (tour.isAssigned)
                ElevatedButton.icon(
                  onPressed: () => _start(tour.tourId),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('بدء الجولة'),
                ),
              if (tour.isInProgress) ...[
                ElevatedButton.icon(
                  onPressed: () => _addPoint(tour.tourId),
                  icon: const Icon(Icons.add_location),
                  label: const Text('إضافة نقطة مسار'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _complete(tour.tourId),
                        child: const Text('إنهاء الجولة'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _send(tour.tourId),
                        child: const Text('إرسال للمدير'),
                      ),
                    ),
                  ],
                ),
              ],
              if (tour.isCompleted)
                ElevatedButton.icon(
                  onPressed: () => _send(tour.tourId),
                  icon: const Icon(Icons.send),
                  label: const Text('إرسال للمدير'),
                ),
              if (tour.isSent)
                const Text('تم إرسال المسار للمدير ✔',
                    style: TextStyle(color: AppTheme.successColor)),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _viewPath(tour),
                icon: const Icon(Icons.route),
                label: const Text('عرض المسار'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'assigned':
        return 'مسندة';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتملة';
      case 'sent':
        return 'أُرسلت';
      default:
        return s;
    }
  }
}
