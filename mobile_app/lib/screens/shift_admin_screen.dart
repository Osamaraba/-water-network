import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class ShiftAdminScreen extends StatefulWidget {
  const ShiftAdminScreen({super.key});

  @override
  State<ShiftAdminScreen> createState() => _ShiftAdminScreenState();
}

class _ShiftAdminScreenState extends State<ShiftAdminScreen> {
  List<dynamic> _shifts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _shifts = await ApiService.getShifts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply(int shiftId) async {
    try {
      await ApiService.applyShift(shiftId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تطبيق الوردية على الفرقة'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    }
  }

  Future<void> _create() async {
    final nameCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 16, minute: 0);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('وردية جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الوردية', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(labelText: 'الفرقة/القسم', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: start);
                          if (t != null) setSt(() => start = t);
                        },
                        child: Text('البداية: ${start.format(ctx)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: end);
                          if (t != null) setSt(() => end = t);
                        },
                        child: Text('النهاية: ${end.format(ctx)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.createShift({
                    'shift_name': nameCtrl.text.trim(),
                    'department': deptCtrl.text.trim().isEmpty ? null : deptCtrl.text.trim(),
                    'start_time': '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                    'end_time': '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                  });
                  await _load();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.dangerColor),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الورديات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _shifts.length,
                itemBuilder: (context, i) {
                  final s = _shifts[i];
                  return ListTile(
                    title: Text(s['shift_name'] ?? ''),
                    subtitle: Text(
                      '${s['department'] ?? 'عام'} | ${s['start_time']} - ${s['end_time']}'
                      '${s['is_night_shift'] == true ? ' (ليلية)' : ''}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _apply(s['shift_id']),
                      child: const Text('تطبيق على الفرقة'),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
    );
  }
}
