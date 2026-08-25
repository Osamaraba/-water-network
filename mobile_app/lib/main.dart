import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/splash_screen.dart';
import 'services/background_service.dart';
import 'services/local_storage_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Friendly fallback instead of the raw red error screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('حدث خطأ غير متوقع في التطبيق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(details.exceptionAsString(),
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  };

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();
  await LocalStorageService.init();

  // Initialize background service
  await BackgroundService.initialize();

  runApp(const YarmoukWaterApp());
}

class YarmoukWaterApp extends StatelessWidget {
  const YarmoukWaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc()),
          BlocProvider(create: (_) => LocationBloc()),
          BlocProvider(create: (_) => SyncBloc()),
        ],
        child: MaterialApp(
          title: 'Yarmouk Water',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          locale: const Locale('ar', 'JO'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'JO'),
            Locale('en', 'US'),
          ],
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
