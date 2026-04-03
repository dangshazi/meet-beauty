import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAccumulateOverlays = 'accumulate_overlays';

class SettingsProvider extends ChangeNotifier {
  bool _accumulateOverlays = true;

  bool get accumulateOverlays => _accumulateOverlays;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _accumulateOverlays = prefs.getBool(_kAccumulateOverlays) ?? true;
    notifyListeners();
  }

  Future<void> setAccumulateOverlays(bool value) async {
    if (_accumulateOverlays == value) return;
    _accumulateOverlays = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAccumulateOverlays, value);
    notifyListeners();
  }
}
