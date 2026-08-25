import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  final regBytes = File('assets/fonts/tajawal_regular.ttf').readAsBytesSync();
  final reg = pw.Font.ttf(ByteData.sublistView(regBytes));
  final pdf = pw.Document();
  pdf.addPage(pw.Page(
    build: (c) => pw.Center(child: pw.Text('????? ???? ???????', style: pw.TextStyle(font: reg, fontSize: 24))),
  ));
  final bytes = await pdf.save();
  print('PDF bytes: ${bytes.length}');
}
