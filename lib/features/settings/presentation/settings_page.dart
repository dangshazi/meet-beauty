import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meet_beauty/l10n/app_localizations.dart';
import 'package:meet_beauty/shared/providers/locale_provider.dart';
import 'package:meet_beauty/shared/providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.settingsLanguage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          RadioGroup<Locale?>(
            groupValue: localeProvider.locale,
            onChanged: (v) => localeProvider.setLocale(v),
            child: Column(
              children: [
                RadioListTile<Locale?>(
                  title: Text(l10n.settingsLanguageSystem),
                  subtitle: Text(
                    _systemLocaleDescription(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: null,
                ),
                RadioListTile<Locale?>(
                  title: Text(l10n.settingsLanguageEn),
                  value: const Locale('en'),
                ),
                RadioListTile<Locale?>(
                  title: Text(l10n.settingsLanguageZh),
                  value: const Locale('zh'),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          SwitchListTile(
            title: Text(l10n.settingsAccumulateOverlays),
            subtitle: Text(l10n.settingsAccumulateOverlaysDesc),
            value: settingsProvider.accumulateOverlays,
            onChanged: (v) =>
                context.read<SettingsProvider>().setAccumulateOverlays(v),
          ),
        ],
      ),
    );
  }

  String _systemLocaleDescription() {
    final platformLocales = WidgetsBinding.instance.platformDispatcher.locales;
    if (platformLocales.isEmpty) return '—';
    final systemLang = platformLocales.first.languageCode;
    return systemLang.startsWith('zh') ? '中文' : 'English';
  }
}
