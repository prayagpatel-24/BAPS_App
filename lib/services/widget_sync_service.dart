import 'package:flutter/services.dart';

import '../models/mukhpath_item.dart';
import '../models/vachanamrut_quote.dart';
import 'app_settings_service.dart';

class WidgetSyncService {
  WidgetSyncService({MethodChannel? channel}) : _channel = channel ?? const MethodChannel('vachanamrut_app/widget');

  final MethodChannel _channel;

  Future<void> syncState({
    required AppSettingsService settingsService,
    required List<VachanamrutQuote> quotes,
    required List<MukhpathItem> mukhpathItems,
  }) async {
    await settingsService.initialize();
    final payload = <String, dynamic>{
      'appMode': settingsService.appMode.name,
      'quoteIntervalMinutes': settingsService.quoteInterval.inMinutes,
      'mukhpathIntervalMinutes': settingsService.mukhpathInterval.inMinutes,
      'language': settingsService.displayLanguage.name,
      'completedMukhpathIds': settingsService.completedMukhpathIds.toList(),
      'quotes': quotes.map((quote) => quote.toJson()).toList(),
      'mukhpathItems': mukhpathItems.map((item) => item.toJson()).toList(),
    };
    await _channel.invokeMethod<void>('syncState', payload);
  }

  Future<void> refreshWidgets() async {
    await _channel.invokeMethod<void>('refreshWidgets');
  }
}

extension on VachanamrutQuote {
  Map<String, String> toJson() {
    return {
      'reference': reference,
      'title': title,
      'quote': quote,
      'meaning': meaning,
    };
  }
}

extension on MukhpathItem {
  Map<String, String> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
    };
  }
}
