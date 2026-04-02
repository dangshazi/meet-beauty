import 'package:flutter/material.dart';

/// Manages the app's locale at runtime.
///
/// `null` means "follow system default".
/// Set to a concrete [Locale] to override.
class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  void setLocale(Locale? locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}
