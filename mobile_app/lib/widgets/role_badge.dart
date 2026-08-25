import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final double fontSize;

  const RoleBadge({
    super.key,
    required this.role,
    this.fontSize = 11,
  });

  Color get _backgroundColor {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return const Color(0xFFEDE7F6);
      case 'hr_manager':
        return const Color(0xFFFCE4EC);
      case 'branch_manager':
        return const Color(0xFFE3F2FD);
      case 'field_supervisor':
        return const Color(0xFFFFF3E0);
      case 'maintenance_tech':
        return const Color(0xFFE8F5E9);
      case 'water_distributor':
        return const Color(0xFFE0F7FA);
      case 'collector':
        return const Color(0xFFF3E5F5);
      case 'gis_engineer':
        return const Color(0xFFF1F8E9);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color get _textColor {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return const Color(0xFF7B1FA2);
      case 'hr_manager':
        return const Color(0xFFC2185B);
      case 'branch_manager':
        return const Color(0xFF1565C0);
      case 'field_supervisor':
        return const Color(0xFFEF6C00);
      case 'maintenance_tech':
        return const Color(0xFF2E7D32);
      case 'water_distributor':
        return const Color(0xFF00838F);
      case 'collector':
        return const Color(0xFF6A1B9A);
      case 'gis_engineer':
        return const Color(0xFF558B2F);
      default:
        return const Color(0xFF616161);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        Helpers.getRoleLabel(role),
        style: TextStyle(
          fontSize: fontSize,
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
