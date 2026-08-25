import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../models/incident_model.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  bool _loading = false;
  List<dynamic> _incidents = [];
  final _typeCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _incidents = await ApiService.getIncidents();
    } catch (e) {
      _snack('تعذر تحميل البلاغات: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _create() async {
    if (_typeCtrl.text.trim().isEmpty || _titleCtrl.text.trim().isEmpty) {
      _snack('أدخل نوع البلاغ والعنوان');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.createIncident({
        'incident_type': _typeCtrl.text.trim(),
        'priority': _priority,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      });
      _snack('تم إنشاء البلاغ');
      _typeCtrl.clear();
      _titleCtrl.clear();
      _descCtrl.clear();
      Navigator.pop(context);
      await _load();
    } catch (e) {
      _snack('خطأ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(String action, int id) async {
    try {
      if (action == 'accept') {
        await ApiService.acceptIncident(id);
      } else if (action == 'arrive') {
        final pos = await Geolocator.getCurrentPosition();
        await ApiService.arriveIncident(id, pos.latitude, pos.longitude);
      } else if (action == 'start') {
        await ApiService.startIncident(id);
      } else if (action == 'complete') {
        await ApiService.completeIncident(id);
      }
      _snack('تم التحديث');
      await _load();
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  List<Widget> _actionsFor(Incident inc) {
    switch (inc.status) {
      case 'new':
      case 'assigned':
        return [ElevatedButton(onPressed: () => _act('accept', inc.incidentId), child: const Text('قبول'))];
      case 'accepted':
      case 'en_route':
        return [ElevatedButton(onPressed: () => _act('arrive', inc.incidentId), child: const Text('وصول'))];
      case 'arrived':
        return [ElevatedButton(onPressed: () => _act('start', inc.incidentId), child: const Text('بدء الإصلاح'))];
      case 'in_progress':
        return [ElevatedButton(onPressed: () => _act('complete', inc.incidentId), child: const Text('إنهاء'))];
      default:
        return [const Text('مغلق', style: TextStyle(color: AppTheme.textSecondary))];
    }
  }

  void _showCreate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('بلاغ جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _typeCtrl,
              decoration: const InputDecoration(labelText: 'النوع', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              items: const [
                DropdownMenuItem(value: 'low', child: Text('منخفض')),
                DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                DropdownMenuItem(value: 'high', child: Text('عالي'),),
                DropdownMenuItem(value: 'critical', child: Text('حرج')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'medium'),
              decoration: const InputDecoration(labelText: 'الأولوية', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _create, child: const Text('إنشاء')),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البلاغات'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _incidents.length,
                itemBuilder: (_, i) {
                  final inc = Incident.fromJson(_incidents[i]);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inc.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('رقم: ${inc.incidentNumber}  •  الحالة: ${inc.status}  •  الأولوية: ${inc.priority}'),
                          const SizedBox(height: 10),
                          Row(children: _actionsFor(inc)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}
