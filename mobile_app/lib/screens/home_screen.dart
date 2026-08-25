import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/employee_model.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/sync_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/role_badge.dart';
import '../widgets/sync_status_bar.dart';
import '../widgets/status_indicator.dart';
import 'attendance_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'evaluation_manager_screen.dart';
import 'incentives_screen.dart';
import 'inspection_tour_screen.dart';
import 'incidents_screen.dart';
import 'departures_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<SyncBloc>().add(SyncStart());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final employee = authState.employee;
        final screens = _getScreensForRole(employee);

        return Scaffold(
          appBar: AppBar(
            title: const Text('نظام مياه اليرموك'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SettingsScreen(employee: employee)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              const SyncStatusBar(),
              Expanded(child: screens[_currentIndex]),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: _getNavItemsForRole(employee),
          ),
        );
      },
    );
  }

  List<Widget> _getScreensForRole(Employee employee) {
    final screens = <Widget>[
      _DashboardScreen(),
      const AttendanceScreen(),
      const MapScreen(),
    ];
    if (employee.roleId == 12) {
      screens.add(const InspectionTourScreen());
    } else if (RoleConstants.hasPermission(employee.roleId, 'evaluation.create')) {
      screens.add(const EvaluationManagerScreen());
      if (RoleConstants.hasPermission(employee.roleId, 'incentive.manage')) {
        screens.add(const IncentivesScreen());
      }
    } else if (employee.roleId == 11) {
      screens.add(_MaintenanceScreen());
    } else if (employee.roleId == 14) {
      screens.add(_CollectorScreen());
    }
    if (_incidentCapable(employee.roleId)) {
      screens.add(const IncidentsScreen());
    }
    screens.add(const DeparturesScreen());
    screens.add(const ProfileScreen());
    return screens;
  }

  bool _incidentCapable(int roleId) =>
      RoleConstants.hasPermission(roleId, 'incident.view') ||
      RoleConstants.hasPermission(roleId, 'incident.accept') ||
      RoleConstants.hasPermission(roleId, 'incident.create');

  List<BottomNavigationBarItem> _getNavItemsForRole(Employee employee) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
      const BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: 'الحضور'),
      const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'الخريطة'),
    ];
    if (employee.roleId == 12) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.route), label: 'جولات التفتيش'));
    } else if (RoleConstants.hasPermission(employee.roleId, 'evaluation.create')) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.star_rate), label: 'تقييم الأداء'));
      if (RoleConstants.hasPermission(employee.roleId, 'incentive.manage')) {
        items.add(const BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'الحوافز'));
      }
    } else if (employee.roleId == 11) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.build), label: 'الصيانة'));
    } else if (employee.roleId == 14) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'الجباية'));
    }
    if (_incidentCapable(employee.roleId)) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.report_problem), label: 'البلاغات'));
    }
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.exit_to_app), label: 'المغادرات'));
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف'));
    return items;
  }
}

class _DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();

        final employee = state.employee;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(employee),
              const SizedBox(height: 16),
              _buildQuickActions(context, employee),
              const SizedBox(height: 16),
              _buildStatsSection(),
              const SizedBox(height: 16),
              _buildRecentActivity(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(Employee employee) {
    final name = employee.fullName.trim();
    final initials = name.isEmpty
        ? '؟'
        : name.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join('');
    final firstName = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً، $firstName',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  RoleBadge(role: employee.roleName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Employee employee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.login,
                label: 'تسجيل دخول',
                color: AppTheme.successColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.map,
                label: 'الخريطة',
                color: AppTheme.infoColor,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.assignment,
                label: 'المهام',
                color: AppTheme.warningColor,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إحصائيات اليوم',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.access_time,
                label: 'ساعات العمل',
                value: '0',
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                label: 'المهام المنجزة',
                value: '0',
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'النشاط الأخير',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text(
                    'لا يوجد نشاط حديث',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('شاشة الصيانة'));
  }
}

class _CollectorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('شاشة الجباية'));
  }
}

class _DistributorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('شاشة التوزيع'));
  }
}
