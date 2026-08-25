import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../models/incentive_model.dart';

class IncentivesScreen extends StatefulWidget {
  const IncentivesScreen({super.key});

  @override
  State<IncentivesScreen> createState() => _IncentivesScreenState();
}

class _IncentivesScreenState extends State<IncentivesScreen> {
  bool _loading = false;
  List<dynamic> _incentives = [];
  final _employeeCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _employeeCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _incentives = await ApiService.getIncentives();
    } catch (e) {
      _snack('تعذر تحميل الحوافز: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _compute() async {
    final empId = int.tryParse(_employeeCtrl.text.trim());
    if (empId == null || _startCtrl.text.isEmpty || _endCtrl.text.isEmpty) {
      _snack('أدخل رقم الموظف وتاريخي البداية والنهاية');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.computeIncentive({
        'employee_id': empId,
        'period_start': _startCtrl.text.trim(),
        'period_end': _endCtrl.text.trim(),
      });
      _snack('تم احتساب الحافز');
      await _load();
    } catch (e) {
      _snack('خطأ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Incentive inc) async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null) {
      _snack('أدخل قيمة الحافز');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.approveIncentive(inc.incentiveId, {
        'incentive_amount': amount,
        'status': 'approved',
      });
      _snack('تم اعتماد الحافز');
      _amountCtrl.clear();
      await _load();
    } catch (e) {
      _snack('خطأ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جدول الحوافز')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildComputeForm(),
                  const SizedBox(height: 16),
                  const Text('الحوافز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ..._incentives.map((i) => _incentiveCard(Incentive.fromJson(i))),
                  if (_incentives.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('لا توجد حوافز'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildComputeForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('احتساب حافز لفترة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _employeeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'رقم الموظف', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _startCtrl,
              decoration: const InputDecoration(
                labelText: 'بداية الفترة (ISO)', border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _endCtrl,
              decoration: const InputDecoration(
                labelText: 'نهاية الفترة (ISO)', border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _compute,
                child: const Text('احتساب'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _incentiveCard(Incentive inc) {
    final isPending = inc.status == 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الموظف #${inc.employeeId}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('الفترة: ${inc.periodStart} → ${inc.periodEnd}'),
            Text('متوسط السرعة: ${inc.avgSpeed ?? '-'}  •  متوسط الدقة: ${inc.avgAccuracy ?? '-'}'),
            Text('درجة الأداء: ${inc.performanceScore ?? '-'}'),
            Text('الحالة: ${inc.status}'),
            if (inc.incentiveAmount != null) Text('قيمة الحافز: ${inc.incentiveAmount}'),
            if (isPending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'قيمة الحافز',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _approve(inc),
                    child: const Text('اعتماد'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
