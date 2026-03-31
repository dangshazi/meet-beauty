import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:meet_beauty/app/router.dart';
import 'package:meet_beauty/app/theme/app_theme.dart';
import 'package:meet_beauty/shared/config/app_config.dart';

class MeetBeautyApp extends StatelessWidget {
  /// Optional providers override — pass in tests to inject mocks.
  final List<SingleChildWidget>? overrideProviders;

  /// Optional router override — pass a fresh [GoRouter] in tests to avoid
  /// shared navigation state between test cases.
  final RouterConfig<Object>? routerConfig;

  const MeetBeautyApp({
    super.key,
    this.overrideProviders,
    this.routerConfig,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: overrideProviders ?? AppConfig.providers,
      child: MaterialApp.router(
        title: AppConfig.appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: routerConfig ?? appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
