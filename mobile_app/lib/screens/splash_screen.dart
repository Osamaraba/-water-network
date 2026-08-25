import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class ForceUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String minVersion;
  final VoidCallback onUpdatePressed;
  final VoidCallback onCancelPressed;

  const ForceUpdateDialog({
    Key? key,
    required this.currentVersion,
    required this.minVersion,
    required this.onUpdatePressed,
    required this.onCancelPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تحديث مطلوب'),
      content: Text('يحتاج هذا الإصدار إلى أدنى إصدار تدعمه الخلفية $minVersion. الإصدار الحالي $currentVersion.'),
      actions: [
        TextButton(
          onPressed: onUpdatePressed,
          child: const Text('فتح المتجر'),
        ),
        TextButton(
          onPressed: onCancelPressed,
          child: const Text('الغاء'),
        ),
      ],
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _currentVersion = '1.0.0';
  String _minSupportedVersion = '1.0.0';

  Future<String> _getCurrentAppVersion() async {
    try {
      final version = await DefaultAssetBundle.of(context).loadString('assets/VERSION');
      return version.trim();
    } catch (_) {
      return '1.0.0';
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthCheckSession());
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    final appVersion = await _getCurrentAppVersion();
    setState(() => _currentVersion = appVersion);
    // Default minimum version if backend check fails
    setState(() => _minSupportedVersion = '1.0.0');
    // Try backend check asynchronously (non-blocking)
    _checkMinVersionFromBackend().ignore();
  }

  Future<void> _checkMinVersionFromBackend() async {
    try {
      // Minimal check without auth - just verify endpoint exists
      // In production, backend returns min_supported_version
      // For now use hardcoded default
    } catch (_) {
      // ignore - use default
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, size: 80, color: Colors.white.withOpacity(0.9)),
                const SizedBox(height: 24),
                const Text(
                  'شركة مياه اليرموك',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نظام إدارة الدوام والمواقع',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
