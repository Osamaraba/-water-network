import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/employee_model.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../screens/live_tracking_screen.dart';
import '../screens/incidents_screen.dart';
import '../screens/departures_screen.dart';
import '../screens/evaluation_manager_screen.dart';
import '../screens/incentives_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/web_dashboard.dart';
import '../screens/employees_screen.dart';
import '../screens/settings_screen.dart';

class WebAdminShell extends StatefulWidget {
  final Employee employee;
  const WebAdminShell({super.key, required this.employee});

  @override
  State<WebAdminShell> createState() => _WebAdminShellState();
}

class _Module {
  final String title;
  final IconData icon;
  final Widget screen;
  final String? permission;
  const _Module(this.title, this.icon, this.screen, this.permission);
}

class _WebAdminShellState extends State<WebAdminShell> {
  int _index = 0;

  late final List<_Module> _modules;

  @override
  void initState() {
    super.initState();
    final roleId = widget.employee.roleId;
    _modules = [
      const _Module('لوحة المعلومات', Icons.dashboard, WebDashboard(), null),
      const _Module('الخريطة الحية', Icons.people_alt, LiveTrackingScreen(), 'gps.view_live'),
      const _Module('الموظفون', Icons.badge, EmployeesScreen(), 'employee.view'),
      const _Module('البلاغات', Icons.report_problem, IncidentsScreen(), 'incident.view'),
      const _Module('المغادرات', Icons.exit_to_app, DeparturesScreen(), 'departure.view_own'),
      const _Module('التقييمات', Icons.star_rate, EvaluationManagerScreen(), 'evaluation.view'),
      const _Module('الحوافز', Icons.emoji_events, IncentivesScreen(), 'incentive.view'),
      _Module('الإعدادات', Icons.settings, SettingsScreen(employee: widget.employee), null),
    ].where((m) => m.permission == null || RoleConstants.hasPermission(roleId, m.permission!)).toList();

    if (RoleConstants.hasPermission(roleId, 'attendance.view') ||
        RoleConstants.hasPermission(roleId, 'incentive.view')) {
      _modules.add(const _Module('التقارير', Icons.description, ReportsScreen(), null));
    }

    if (_index >= _modules.length) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            Container(
              width: 240,
              color: AppTheme.primaryDark,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Icon(Icons.water_drop, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  const Text('مياه اليرموك',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(widget.employee.roleName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _modules.length,
                      itemBuilder: (_, i) => _navItem(i),
                    ),
                  ),
                  _logoutButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
                      ],
                    ),
                    child: Text(_modules[_index].title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: _modules[_index].screen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i) {
    final selected = i == _index;
    return Container(
      color: selected ? AppTheme.primaryColor.withValues(alpha: 0.25) : null,
      child: ListTile(
        leading: Icon(_modules[i].icon, color: Colors.white),
        title: Text(_modules[i].title, style: const TextStyle(color: Colors.white)),
        selected: selected,
        onTap: () => setState(() => _index = i),
      ),
    );
  }

  Widget _logoutButton() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.white70),
      title: const Text('تسجيل خروج', style: TextStyle(color: Colors.white70)),
      onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
    );
  }
}
