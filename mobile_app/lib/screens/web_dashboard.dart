import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class WebDashboard extends StatefulWidget {
  const WebDashboard({super.key});

  @override
  State<WebDashboard> createState() => _WebDashboardState();
}

class _WebDashboardState extends State<WebDashboard> {
  bool _loading = true;
  int _employees = 0;
  int _incidents = 0;
  int _live = 0;
  int _pendingDepartures = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final emps = await ApiService.getEmployees();
      final incs = await ApiService.getIncidents();
      final live = await ApiService.getLiveEmployees();
      final deps = await ApiService.getDepartures(status: 'pending');
      if (mounted) {
        setState(() {
          _employees = emps.length;
          _incidents = incs.length;
          _live = live.length;
          _pendingDepartures = deps.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نظرة عامة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _statCard('الموظفون', _employees, Icons.badge, AppTheme.primaryColor),
                    _statCard('متصلون الآن', _live, Icons.people_alt, AppTheme.successColor),
                    _statCard('البلاغات', _incidents, Icons.report_problem, AppTheme.warningColor),
                    _statCard('مغادرات بانتظار الاعتماد', _pendingDepartures, Icons.exit_to_app, AppTheme.dangerColor),
                  ],
                ),
              ],
            ),
          );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return SizedBox(
      width: 240,
      height: 120,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        Text(label, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
