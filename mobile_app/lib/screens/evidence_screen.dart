import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class EvidenceScreen extends StatefulWidget {
  final int logId;
  final bool isCheckIn;
  final double latitude;
  final double longitude;

  const EvidenceScreen({
    super.key,
    required this.logId,
    required this.isCheckIn,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    // Auto-capture after a short delay
    Future.delayed(const Duration(milliseconds: 500), _captureEvidence);
  }

  Future<void> _captureEvidence() async {
    setState(() => _isCapturing = true);
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        // Add watermark
        final watermarked = await _addWatermark(image);
        // Save to local storage
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'evidence_${widget.logId}_${widget.isCheckIn ? 'in' : 'out'}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(watermarked);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ دليل التوثيق'), backgroundColor: AppTheme.successColor),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التقاط الصورة: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<Uint8List> _addWatermark(Uint8List imageBytes) async {
    final original = img.decodeImage(imageBytes);
    if (original == null) return imageBytes;

    final watermarked = img.copyResize(original, width: original.width);

    // Add text watermark
    final timestamp = Helpers.formatDateTime(DateTime.now());
    final hash = 'HASH-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';

    // Draw semi-transparent overlay at bottom
    final overlay = img.fillRect(
      watermarked,
      x1: 0,
      y1: watermarked.height - 120,
      x2: watermarked.width,
      y2: watermarked.height,
      color: img.ColorRgba8(0, 0, 0, 180),
    );

    // Note: In production, use proper text rendering
    // This is a simplified version
    return img.encodePng(overlay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCheckIn ? 'تسجيل الدخول' : 'تسجيل الخروج'),
        automaticallyImplyLeading: false,
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: AppTheme.backgroundColor,
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isCheckIn ? Icons.login : Icons.logout,
                      size: 64,
                      color: widget.isCheckIn ? AppTheme.successColor : AppTheme.dangerColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isCheckIn ? 'تم تسجيل الدخول بنجاح' : 'تم تسجيل الخروج بنجاح',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow('الوقت', Helpers.formatDateTime(DateTime.now())),
                    _buildInfoRow('الموقع', '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}'),
                    _buildInfoRow('المعاملة', 'TXN-${DateTime.now().millisecondsSinceEpoch}'),
                    const SizedBox(height: 24),
                    if (_isCapturing)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('متابعة'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.left),
          ),
        ],
      ),
    );
  }
}
