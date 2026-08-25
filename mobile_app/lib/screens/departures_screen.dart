import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../models/departure_model.dart';

class DeparturesScreen extends StatefulWidget {
  const DeparturesScreen({super.key});

  @override
  State<DeparturesScreen> createState() => _DeparturesScreenState();
}

class _DeparturesScreenState extends State<DeparturesScreen> {
  bool _loading = false;
  List<dynamic> _mine = [];
  List<dynamic> _pending = [];
  bool _canReview = false;

  final _formKey = GlobalKey<FormState>();
  String _type = 'official';
  DateTime? _departure;
  DateTime? _return;
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _canReview = RoleConstants.hasPermission(authState.employee.roleId, 'departure.hr_review');
    }
    _load();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _mine = await ApiService.getMyDepartures();
      if (_canReview) _pending = await ApiService.getDepartures();
    } catch (e) {
      _snack('تعذر تحميل الطلبات: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pick(bool isDeparture) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isDeparture) {
        _departure = dt;
      } else {
        _return = dt;
      }
    });
  }

  Future<void> _submit() async {
    if (_departure == null || _return == null) {
      _snack('حدد وقت المغادرة والعودة');
      return;
    }
    if (_return!.isBefore(_departure!) || _return!.isAtSameMomentAs(_departure!)) {
      _snack('وقت العودة يجب أن يكون بعد المغادرة');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.createDeparture({
        'departure_type': _type,
        'departure_time': _departure!.toUtc().toIso8601String(),
        'return_time': _return!.toUtc().toIso8601String(),
        'reason': _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      });
      _snack('تم إرسال الطلب إلى الموارد البشرية');
      _reasonCtrl.clear();
      _departure = null;
      _return = null;
      await _load();
    } catch (e) {
      _snack('خطأ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(Departure d, String status) async {
    try {
      await ApiService.reviewDeparture(d.departureId, status);
      _snack(status == 'approved' ? 'تم الاعتماد' : 'تم الرفض');
      await _load();
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_canReview) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('المغادرات'),
            bottom: const TabBar(
              tabs: [Tab(text: 'طلباتي'), Tab(text: 'موافقة الموارد')],
            ),
            actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
          ),
          body: TabBarView(
            children: [
              _buildSelf(),
              _buildReview(),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('المغادرات'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _buildSelf(),
    );
  }

  Widget _buildSelf() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('طلب مغادرة جديد', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'official', child: Text('رسمية')),
                      DropdownMenuItem(value: 'personal', child: Text('خاصة')),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'official'),
                    decoration: const InputDecoration(labelText: 'النوع', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('وقت المغادرة'),
                    subtitle: Text(_departure == null ? 'غير محدد' : _fmt(_departure!)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => _pick(true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('وقت العودة'),
                    subtitle: Text(_return == null ? 'غير محدد' : _fmt(_return!)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => _pick(false),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'السبب (اختياري)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _submit, child: const Text('إرسال للاعتماد')),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('طلباتي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_loading) const Center(child: CircularProgressIndicator()),
        ..._mine.map((j) => _card(Departure.fromJson(j), withEmployee: false)),
        if (!_loading && _mine.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد طلبات'))),
      ],
    );
  }

  Widget _buildReview() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final sorted = [..._pending]
      ..sort((a, b) {
        final sa = a['status'] == 'pending' ? 0 : 1;
        final sb = b['status'] == 'pending' ? 0 : 1;
        return sa.compareTo(sb);
      });
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('طلبات الموظفين', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...sorted.map((j) => _card(Departure.fromJson(j), withEmployee: true)),
        if (!_loading && _pending.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد طلبات'))),
      ],
    );
  }

  Widget _card(Departure d, {required bool withEmployee}) {
    final pending = d.status == 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(d.typeLabel)),
                const SizedBox(width: 8),
                Chip(
                  label: Text(d.statusLabel),
                  backgroundColor: pending
                      ? AppTheme.warningColor.withValues(alpha: 0.2)
                          : d.status == 'approved'
                          ? AppTheme.successColor.withValues(alpha: 0.2)
                          : AppTheme.dangerColor.withValues(alpha: 0.2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (withEmployee && d.employeeName != null)
              Text('الموظف: ${d.employeeName}${d.employeeNumber != null ? ' (#${d.employeeNumber})' : ''}'),
            Text('المغادرة: ${d.departureTime != null ? _fmtParsed(d.departureTime!) : '-'}'),
            Text('العودة: ${d.returnTime != null ? _fmtParsed(d.returnTime!) : '-'}'),
            if (d.reason != null && d.reason!.isNotEmpty) Text('السبب: ${d.reason}'),
            if (d.reviewNote != null && d.reviewNote!.isNotEmpty) Text('ملاحظة الاعتماد: ${d.reviewNote}'),
            if (withEmployee && pending)
              Row(
                children: [
                  ElevatedButton(onPressed: () => _review(d, 'approved'), child: const Text('اعتماد')),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: () => _review(d, 'rejected'), child: const Text('رفض')),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);
  String _fmtParsed(String iso) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
