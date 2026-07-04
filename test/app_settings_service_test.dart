import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vachanamrut_app/services/app_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists quote interval and language preferences', () async {
    final service = AppSettingsService();
    await service.initialize();

    await service.setQuoteInterval(Duration(hours: 3));
    await service.setDisplayLanguage(AppLanguage.gujaratiWithEnglish);

    final reloaded = AppSettingsService();
    await reloaded.initialize();

    expect(reloaded.quoteInterval, Duration(hours: 3));
    expect(reloaded.displayLanguage, AppLanguage.gujaratiWithEnglish);
  });
}
