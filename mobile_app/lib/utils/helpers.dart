import 'package:intl/intl.dart';

class Helpers {
  static String formatDateTime(DateTime dateTime, {String pattern = 'yyyy-MM-dd HH:mm:ss'}) {
    return DateFormat(pattern, 'ar').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd', 'ar').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss', 'ar').format(dateTime);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} كم';
    }
    return '${meters.toStringAsFixed(0)} م';
  }

  static String getRoleLabel(String role) {
    final labels = {
      'super_admin': 'مدير النظام',
      'general_manager': 'المدير العام',
      'hr_manager': 'مدير الموارد البشرية',
      'branch_manager': 'مدير الفرع',
      'maintenance_director': 'مدير الصيانة',
      'distribution_director': 'مدير التوزيع',
      'sewage_director': 'مدير الصرف الصحي',
      'field_supervisor': 'مشرف ميداني',
      'office_employee': 'موظف مكتبي',
      'office_field_employee': 'مكتبي وميداني',
      'maintenance_tech': 'فني صيانة',
      'water_distributor': 'موزع مياه',
      'sewage_worker': 'عامل صرف صحي',
      'collector': 'جابي',
      'gis_engineer': 'مهندس GIS',
      'auditor': 'مدقق',
      'read_only': 'قراءة فقط',
    };
    return labels[role] ?? role;
  }

  static String getTrustStatusLabel(String status) {
    final labels = {
      'valid': 'صالح',
      'review': 'مراجعة',
      'suspicious': 'مشبوه',
      'rejected': 'مرفوض',
    };
    return labels[status] ?? status;
  }

  static String getTrustStatusColor(String status) {
    final colors = {
      'valid': '0xFF4CAF50',
      'review': '0xFFFF9800',
      'suspicious': '0xFFF44336',
      'rejected': '0xFFB71C1C',
    };
    return colors[status] ?? '0xFF757575';
  }

  static String getIncidentStatusLabel(String status) {
    final labels = {
      'new': 'جديد',
      'assigned': 'معين',
      'accepted': 'مقبول',
      'en_route': 'في الطريق',
      'arrived': 'تم الوصول',
      'in_progress': 'قيد الإصلاح',
      'waiting': 'في الانتظار',
      'completed': 'مكتمل',
      'verified': 'تم التحقق',
      'closed': 'مغلق',
      'cancelled': 'ملغي',
    };
    return labels[status] ?? status;
  }
}
