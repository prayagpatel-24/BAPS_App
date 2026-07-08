import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { vachanamrut, mukhpath }

enum WidgetContentMode { vachanamrut, mukhpath }

enum AppLanguage { english, gujarati, gujaratiWithEnglish }

class AppSettingsService {
  AppSettingsService({SharedPreferences? preferences}) : _preferences = preferences;

  static const _quoteIntervalKey = 'quote_interval_minutes';
  static const _displayLanguageKey = 'display_language';
  static const _appModeKey = 'app_mode';
  static const _widgetContentModeKey = 'widget_content_mode';
  static const _mukhpathIntervalKey = 'mukhpath_interval_minutes';
  static const _completedMukhpathKey = 'completed_mukhpath_ids';

  SharedPreferences? _preferences;

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Duration get quoteInterval {
    final minutes = _preferences?.getInt(_quoteIntervalKey) ?? 60;
    return Duration(minutes: minutes);
  }

  Duration get mukhpathInterval {
    final minutes = _preferences?.getInt(_mukhpathIntervalKey) ?? 60;
    return Duration(minutes: minutes);
  }

  AppLanguage get displayLanguage {
    final value = _preferences?.getString(_displayLanguageKey);
    return AppLanguage.values.firstWhere(
      (language) => language.name == value,
      orElse: () => AppLanguage.gujarati,
    );
  }

  AppMode get appMode {
    final value = _preferences?.getString(_appModeKey);
    return AppMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppMode.vachanamrut,
    );
  }

  WidgetContentMode get widgetContentMode {
    final value = _preferences?.getString(_widgetContentModeKey);
    return WidgetContentMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => WidgetContentMode.vachanamrut,
    );
  }

  Set<String> get completedMukhpathIds {
    return _preferences
            ?.getStringList(_completedMukhpathKey)
            ?.toSet() ??
        <String>{};
  }

  Future<void> setQuoteInterval(Duration interval) async {
    await initialize();
    await _preferences!.setInt(_quoteIntervalKey, interval.inMinutes);
  }

  Future<void> setMukhpathInterval(Duration interval) async {
    await initialize();
    await _preferences!.setInt(_mukhpathIntervalKey, interval.inMinutes);
  }

  Future<void> setDisplayLanguage(AppLanguage language) async {
    await initialize();
    await _preferences!.setString(_displayLanguageKey, language.name);
  }

  Future<void> setAppMode(AppMode mode) async {
    await initialize();
    await _preferences!.setString(_appModeKey, mode.name);
  }

  Future<void> setWidgetContentMode(WidgetContentMode mode) async {
    await initialize();
    await _preferences!.setString(_widgetContentModeKey, mode.name);
  }

  Future<void> setModeToggle(bool enabled) async {
    await initialize();
    final appMode = enabled ? AppMode.mukhpath : AppMode.vachanamrut;
    final widgetMode = enabled ? WidgetContentMode.mukhpath : WidgetContentMode.vachanamrut;
    await _preferences!.setString(_appModeKey, appMode.name);
    await _preferences!.setString(_widgetContentModeKey, widgetMode.name);
  }

  Future<void> toggleMukhpathCompletion(String id) async {
    await initialize();
    final completed = completedMukhpathIds.toSet();
    if (completed.contains(id)) {
      completed.remove(id);
    } else {
      completed.add(id);
    }
    await _preferences!.setStringList(_completedMukhpathKey, completed.toList());
  }

  Future<void> clearCompletedMukhpath() async {
    await initialize();
    await _preferences!.remove(_completedMukhpathKey);
  }
}
