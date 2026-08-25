import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yarmouk_water_app/utils/excel_report.dart' as er;

void main() {
  final rows = <Map<String, dynamic>>[
    {
      'employee_number': 'admin',
      'full_name': 'مشرف النظام',
      'department': 'الإدارة',
      'check_in_time': '2026-08-25T08:05:00',
      'check_out_time': '2026-08-25T16:10:00',
      'trust_status': 'valid',
      'overtime_hours': 0,
    },
    {
      'employee_number': 'EMP001',
      'full_name': 'موزع مياه',
      'department': 'التوزيع',
      'check_in_time': '2026-08-25T07:55:00',
      'check_out_time': '2026-08-25T15:50:00',
      'trust_status': 'valid',
      'overtime_hours': 1.5,
    },
  ];

  final incentives = <Map<String, dynamic>>[
    {
      'employee_id': 1,
      'period_start': '2026-08-01',
      'period_end': '2026-08-31',
      'avg_speed': 4.2,
      'avg_accuracy': 4.6,
      'performance_score': 90.0,
      'incentive_amount': null,
      'status': 'pending',
    },
  ];

  testWidgets('Excel report builds with letterhead, RTL and signatures',
      (tester) async {
    final excel = er.buildAttendanceExcel(
      title: 'تقرير الدوام اليومي',
      period: '2026-08-25',
      rows: rows,
    );

    expect(excel.sheets.containsKey('الحضور والانصراف'), isTrue);
    final sheet = excel.sheets['الحضور والانصراف']!;
    expect(sheet.isRTL, isTrue);

    // Company letterhead present at A1
    final a1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value;
    expect(a1, isNotNull);
    expect(a1.toString().contains('شركة مياه اليرموك'), isTrue);

    // A data row exists (row 4)
    final dataCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value;
    expect(dataCell, isNotNull);

    // Save produces bytes
    final bytes = excel.save();
    expect(bytes, isNotNull);
    expect(bytes!.isNotEmpty, isTrue);
  });

  testWidgets('Excel report with incentives adds a second sheet',
      (tester) async {
    final excel = er.buildAttendanceExcel(
      title: 'تقرير فردي شهري',
      period: '2026-08',
      rows: rows,
      incentiveRows: incentives,
    );
    expect(excel.sheets.containsKey('الحوافز'), isTrue);
    final bytes = excel.save();
    expect(bytes, isNotNull);
  });
}
