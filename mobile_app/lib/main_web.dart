import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/sync_provider.dart';
import '../utils/app_theme.dart';
import 'web_root.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const YarmoukWebApp());
}

class YarmoukWebApp extends StatelessWidget {
  const YarmoukWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1280, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc()),
          BlocProvider(create: (_) => LocationBloc()),
          BlocProvider(create: (_) => SyncBloc()),
        ],
        child: MaterialApp(
          title: 'Yarmouk Water - Monitoring',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: const Locale('ar', 'JO'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'JO'), Locale('en', 'US')],
          home: const WebRoot(),
        ),
      ),
    );
  }
}
