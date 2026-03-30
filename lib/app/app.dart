import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meet_beauty/app/router.dart';
import 'package:meet_beauty/app/theme/app_theme.dart';
import 'package:meet_beauty/shared/config/app_config.dart';

class MeetBeautyApp extends StatelessWidget {
  const MeetBeautyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppConfig.providers,
      child: MaterialApp.router(
        title: AppConfig.appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
