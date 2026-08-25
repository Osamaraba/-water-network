import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart' hide TextDirection;

import '../services/api_service.dart';
import '../utils/excel_report.dart' as er;
import '../utils/pdf_report.dart' as pr;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _type = 'daily';
  DateTime _day = DateTime.now();
  DateTime _month = DateTime.now();
  List<dynamic> _employees = [];
  int? _selectedEmployee;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await ApiService.getEmployees();
      if (mounted) {
        setState(() {
          _employees = list;
          if (_employees.isNotEmpty) _selectedEmployee = _employees.first['employee_id'];
        });
      }
    } catch (_) {
      // demo mode already provides mock employees
    }
  }

  String get _dayStr => DateFormat('yyyy-MM-dd').format(_day);
  String get _monthStr => DateFormat('yyyy-MM').format(_month);

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('ar', 'JO'),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('ar', 'JO'),
      helpText: 'اختر شهر التقرير',
    );
    if (picked != null) setState(() => _month = picked);
  }

  Future<void> _generate({required bool printPdf}) async {
    setState(() => _loading = true);
    try {
      List<dynamic> rows;
      List<dynamic>? incentives;
      String title;
      String period;

      if (_type == 'daily') {
        title = 'تقرير الدوام اليومي';
        period = _dayStr;
        rows = await ApiService.getAttendanceReport(date: _dayStr);
      } else {
        title = 'تقرير الدوام الشهري الفردي';
        period = _monthStr;
        if (_selectedEmployee == null) throw Exception('اختر موظفاً');
        rows = await ApiService.getAttendanceReport(
          employeeId: _selectedEmployee,
          month: _monthStr,
        );
        final all = await ApiService.getIncentives(employeeId: _selectedEmployee);
        incentives = all
            .where((i) => '${i['period_start']}'.startsWith(_monthStr))
            .toList();
      }

      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد بيانات للفترة المحددة')),
          );
        }
        return;
      }

      if (printPdf) {
        final bytes = await pr.buildAttendancePdf(
          title: title,
          period: period,
          rows: rows,
          incentiveRows: incentives,
        );
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: '${title}_$period',
        );
      } else {
        final excel = er.buildAttendanceExcel(
          title: title,
          period: period,
          rows: rows,
          incentiveRows: incentives,
        );
        final bytes = excel.save()!;
        _downloadExcel(bytes, '${title}_$period.xlsx');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تصدير ملف Excel')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _downloadExcel(List<int> bytes, String name) {
    final blob = html.Blob(
      [Uint8List.fromList(bytes)],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', name)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text('التقارير', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'نوع التقرير'),
                      items: const [
                        DropdownMenuItem(
                          value: 'daily',
                          child: Text('تقرير الدوام اليومي (لكل الموظفين)'),
                        ),
                        DropdownMenuItem(
                          value: 'individual',
                          child: Text('تقرير فردي شهري (دوام + حوافز)'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                    const SizedBox(height: 16),
                    if (_type == 'daily') ...[
                      Row(
                        children: [
                          Expanded(child: Text('التاريخ: $_dayStr')),
                          ElevatedButton(
                            onPressed: _pickDay,
                            child: const Text('اختيار التاريخ'),
                          ),
                        ],
                      ),
                    ] else ...[
                      DropdownButtonFormField<int>(
                        value: _selectedEmployee,
                        decoration: const InputDecoration(labelText: 'الموظف'),
                        items: _employees
                            .map((e) => DropdownMenuItem<int>(
                                  value: e['employee_id'] as int,
                                  child: Text(
                                    '${e['full_name']} (${e['username']})',
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedEmployee = v),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Text('الشهر: $_monthStr')),
                          ElevatedButton(
                            onPressed: _pickMonth,
                            child: const Text('اختيار الشهر'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loading ? null : () => _generate(printPdf: false),
                          icon: const Icon(Icons.download),
                          label: const Text('تصدير Excel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : () => _generate(printPdf: true),
                          icon: const Icon(Icons.print),
                          label: const Text('طباعة PDF'),
                        ),
                        if (_loading) ...[
                          const SizedBox(width: 16),
                          const CircularProgressIndicator(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ملاحظة: التقارير مروسة بترويسة «شركة مياه اليرموك» وتتضمن خانتي توقيع '
              'مدير الموارد البشرية والمدير العام.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
  }
}
