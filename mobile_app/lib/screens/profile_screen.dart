import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/role_badge.dart';
import 'login_screen.dart';
import 'shift_admin_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        final employee = state.employee;

        return Scaffold(
          appBar: AppBar(title: const Text('الملف الشخصي')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(employee),
                const SizedBox(height: 24),
                _buildInfoSection(employee),
                const SizedBox(height: 24),
                _buildSyncSection(context),
                const SizedBox(height: 24),
                if (RoleConstants.hasPermission(employee.roleId, 'shift.manage'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShiftAdminScreen()),
                        ),
                        icon: const Icon(Icons.schedule),
                        label: const Text('إدارة الورديات'),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildSettingsSection(context),
                const SizedBox(height: 24),
                _buildLogoutButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(employee) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            employee.fullName.split(' ').map((e) => e[0]).take(2).join(''),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          employee.fullName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        RoleBadge(role: employee.roleName),
      ],
    );
  }

  Widget _buildInfoSection(employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.badge, 'رقم الموظف', employee.employeeNumber ?? '-'),
            const Divider(),
            _buildInfoRow(Icons.email, 'البريد', employee.email ?? '-'),
            const Divider(),
            _buildInfoRow(Icons.phone, 'الهاتف', employee.phone ?? '-'),
            const Divider(),
            _buildInfoRow(Icons.business, 'القسم', employee.department ?? '-'),
            const Divider(),
            _buildInfoRow(Icons.location_city, 'الفرع', employee.branch ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('المزامنة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            BlocBuilder<SyncBloc, SyncState>(
              builder: (context, state) {
                String statusText = 'جاهز';
                IconData statusIcon = Icons.cloud_done;
                Color statusColor = AppTheme.successColor;

                if (state is SyncInProgress) {
                  statusText = 'جاري المزامنة...';
                  statusIcon = Icons.sync;
                  statusColor = AppTheme.infoColor;
                } else if (state is SyncOffline) {
                  statusText = 'غير متصل - ${state.pendingCount} عنصر';
                  statusIcon = Icons.cloud_off;
                  statusColor = AppTheme.warningColor;
                } else if (state is SyncError) {
                  statusText = 'خطأ في المزامنة';
                  statusIcon = Icons.error;
                  statusColor = AppTheme.dangerColor;
                }

                return ListTile(
                  leading: Icon(statusIcon, color: statusColor),
                  title: Text(statusText),
                  trailing: TextButton(
                    onPressed: () => context.read<SyncBloc>().add(SyncForceSync()),
                    child: const Text('مزامنة الآن'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications, color: AppTheme.primaryColor),
            title: const Text('الإشعارات'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language, color: AppTheme.primaryColor),
            title: const Text('اللغة'),
            trailing: const Text('العربية'),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info, color: AppTheme.primaryColor),
            title: const Text('عن التطبيق'),
            trailing: const Text('v1.0.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('تأكيد تسجيل الخروج'),
              content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('تسجيل الخروج'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.dangerColor.withOpacity(0.1),
          foregroundColor: AppTheme.dangerColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
