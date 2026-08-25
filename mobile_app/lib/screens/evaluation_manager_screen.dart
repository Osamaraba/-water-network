import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/employee_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../models/performance_evaluation_model.dart';

class EvaluationManagerScreen extends StatefulWidget {
  const EvaluationManagerScreen({super.key});

  @override
  State<EvaluationManagerScreen> createState() => _EvaluationManagerScreenState();
}

class _EvaluationManagerScreenState extends State<EvaluationManagerScreen> {
  bool _loading = false;
  List<dynamic> _evals = [];
  bool _canCreate = false;
  int _speed = 3;
  int _accuracy = 3;
  final _employeeCtrl = TextEditingController();
  final _reportCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _employeeCtrl.dispose();
    _reportCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _evals = _canCreate
          ? await ApiService.getEvaluations()
          : await ApiService.getMyEvaluations();
    } catch (e) {
      _snack('تعذر تحميل التقييمات: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    final empId = int.tryParse(_employeeCtrl.text.trim());
    if (empId == null) {
      _snack('أدخل رقم الموظف المراد تقييمه');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.createEvaluation({
        'employee_id': empId,
        'task_report_id': _reportCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_reportCtrl.text.trim()),
        'speed_score': _speed,
        'accuracy_score': _accuracy,
        'comment': _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      });
      _snack('تم حفظ التقييم');
      _employeeCtrl.clear();
      _reportCtrl.clear();
      _commentCtrl.clear();
      await _load();
    } catch (e) {
      _snack('خطأ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          _canCreate = RoleConstants.hasPermission(state.employee.roleId, 'evaluation.create');
        }
        return _buildBody();
      },
    );
  }

  Widget _buildBody() {
    return Scaffold(
      appBar: AppBar(title: const Text('تقييم الأداء')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_canCreate) _buildForm(),
                  const SizedBox(height: 16),
                  Text(
                    _canCreate ? 'التقييمات المسجلة' : 'تقييماتي',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ..._evals.map((e) => _evalCard(PerformanceEvaluation.fromJson(e))),
                  if (_evals.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('لا توجد تقييمات'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تقييم جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _employeeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'رقم الموظف',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reportCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'رقم تقرير المهمة (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('سرعة الإنجاز'),
            Slider(
              value: _speed.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _speed.toString(),
              onChanged: (v) => setState(() => _speed = v.round()),
            ),
            const Text('دقة الإنجاز'),
            Slider(
              value: _accuracy.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _accuracy.toString(),
              onChanged: (v) => setState(() => _accuracy = v.round()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('حفظ التقييم'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _evalCard(PerformanceEvaluation e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.star_rate, color: AppTheme.primaryColor),
        title: Text('الموظف #${e.employeeId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('السرعة: ${e.speedScore} / 5  •  الدقة: ${e.accuracyScore} / 5'),
            if (e.comment != null && e.comment!.isNotEmpty) Text(e.comment!),
            if (e.createdAt != null) Text(e.createdAt!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
