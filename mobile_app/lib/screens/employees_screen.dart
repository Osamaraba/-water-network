import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  bool _loading = false;
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _employees = await ApiService.getEmployees();
    } catch (e) {
      _snack('تعذر تحميل الموظفين: $e');
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
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('الرقم')),
                    DataColumn(label: Text('الاسم')),
                    DataColumn(label: Text('الدور')),
                    DataColumn(label: Text('القسم')),
                    DataColumn(label: Text('الحالة')),
                  ],
                  rows: _employees.map((e) {
                    final active = e['is_active'] != false;
                    return DataRow(cells: [
                      DataCell(Text('${e['employee_id']}')),
                      DataCell(Text(e['full_name'] ?? e['username'] ?? '-')),
                      DataCell(Text(e['role_name'] ?? '-')),
                      DataCell(Text('${e['department'] ?? '-'}')),
                      DataCell(Text(active ? 'نشط' : 'غير نشط',
                          style: TextStyle(
                              color: active ? AppTheme.successColor : AppTheme.dangerColor))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          );
  }
}
