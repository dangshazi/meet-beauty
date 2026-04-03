import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meet_beauty/shared/providers/settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsProvider', () {
    test('default accumulateOverlays is true', () {
      final provider = SettingsProvider();
      expect(provider.accumulateOverlays, isTrue);
    });

    test('setAccumulateOverlays updates value and notifies listeners', () async {
      final provider = SettingsProvider();
      bool? notifiedValue;
      provider.addListener(() {
        notifiedValue = provider.accumulateOverlays;
      });

      await provider.setAccumulateOverlays(false);

      expect(provider.accumulateOverlays, isFalse);
      expect(notifiedValue, isFalse);
    });

    test('setAccumulateOverlays does not notify when value unchanged', () async {
      final provider = SettingsProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 50));

      notifyCount = 0;
      await provider.setAccumulateOverlays(true); // same as default

      expect(notifyCount, equals(0));
    });

    test('persists value to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = SettingsProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.setAccumulateOverlays(false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('accumulate_overlays'), isFalse);
    });

    test('loads persisted value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'accumulate_overlays': false});

      final provider = SettingsProvider();
      // Wait for async _load to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.accumulateOverlays, isFalse);
    });
  });
}
