import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class TaskReportScreen extends StatefulWidget {
  final int? logId;
  const TaskReportScreen({super.key, this.logId});

  @override
  State<TaskReportScreen> createState() => _TaskReportScreenState();
}

class _ReportItem {
  String description = '';
  DateTime date = DateTime.now();
  TimeOfDay time = TimeOfDay.now();
  String quantity = '';
  String notes = '';
}

class _TaskReportScreenState extends State<TaskReportScreen> {
  final List<_ReportItem> _items = [_ReportItem()];
  DateTime _reportDate = DateTime.now();
  bool _isSaving = false;

  Future<void> _pickDate(BuildContext context, int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _items[index].date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _items[index].date = picked);
  }

  Future<void> _pickTime(BuildContext context, int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _items[index].time,
    );
    if (picked != null) setState(() => _items[index].time = picked);
  }

  Future<void> _submit() async {
    final valid = _items.where((e) => e.description.trim().isNotEmpty).toList();
    if (valid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف بندًا واحدًا على الأقل'), backgroundColor: AppTheme.dangerColor),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final body = {
        'report_date': DateFormat('yyyy-MM-dd').format(_reportDate),
        'log_id': widget.logId,
        'items': valid.map((e) => {
          'work_description': e.description.trim(),
          'work_date': DateFormat('yyyy-MM-dd').format(e.date),
          'work_time': '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}',
          'quantity': double.tryParse(e.quantity) ?? 0,
          'notes': e.notes.trim(),
        }).toList(),
      };
      await ApiService.createTaskReport(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال تقرير الإنجاز'), backgroundColor: AppTheme.successColor),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقرير إنجاز المهمة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('تاريخ التقرير:', style: TextStyle(fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _reportDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setState(() => _reportDate = picked);
                },
                child: Text(Helpers.formatDate(_reportDate)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('الأعمال المنجزة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'وصف العمل', border: OutlineInputBorder()),
                      onChanged: (v) => item.description = v,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickDate(context, i),
                            child: Text('التاريخ: ${Helpers.formatDate(item.date)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickTime(context, i),
                            child: Text('الوقت: ${item.time.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: 'الكمية (اختياري)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => item.quantity = v,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder()),
                      onChanged: (v) => item.notes = v,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          TextButton.icon(
            onPressed: () => setState(() => _items.add(_ReportItem())),
            icon: const Icon(Icons.add),
            label: const Text('إضافة بند عمل'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('إرسال التقرير', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
