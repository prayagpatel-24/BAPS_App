import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/vachanamrut_quote.dart';
import 'services/app_settings_service.dart';
import 'services/mukhpath_repository.dart';
import 'services/quote_repository.dart';
import 'services/widget_sync_service.dart';
import 'widgets/mukhpath_page.dart';
import 'widgets/quote_card.dart';
import 'widgets/settings_page.dart';
import 'widgets/today_panel.dart';

void main() {
  runApp(const VachanamrutApp());
}

class VachanamrutApp extends StatelessWidget {
  const VachanamrutApp({super.key});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF58220);
    const cream = Color(0xFFFFFBF7);
    const ink = Color(0xFF2D241D);

    return MaterialApp(
      title: 'Vachanamrut Daily',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          primary: orange,
          secondary: const Color(0xFF7A4E24),
          surface: Colors.white,
          onSurface: ink,
        ),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFEADFD4)),
          ),
        ),
      ),
      home: const HomeShellPage(),
    );
  }
}

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  final AppSettingsService _settingsService = AppSettingsService();
  final WidgetSyncService _widgetSyncService = WidgetSyncService();
  AppMode _appMode = AppMode.vachanamrut;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _settingsService.initialize();
    if (!mounted) return;
    setState(() {
      _appMode = _settingsService.appMode;
    });
    await _syncWidgetState();
  }

  Future<void> _onSettingsChanged() async {
    if (!mounted) return;
    setState(() {
      _appMode = _settingsService.appMode;
    });
    await _syncWidgetState();
  }

  Future<void> _syncWidgetState() async {
    await _widgetSyncService.syncState(
      settingsService: _settingsService,
      quotes: await QuoteRepository.load(),
      mukhpathItems: MukhpathRepository.loadSampleData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _appMode == AppMode.mukhpath
        ? MukhpathPage(
            settingsService: _settingsService,
            onStateChanged: _onSettingsChanged,
          )
        : VachanamrutHomePage(
            settingsService: _settingsService,
            onSettingsChanged: _onSettingsChanged,
          );
  }
}

class VachanamrutHomePage extends StatefulWidget {
  const VachanamrutHomePage({
    super.key,
    required this.settingsService,
    this.onSettingsChanged,
  });

  final AppSettingsService settingsService;
  final Future<void> Function()? onSettingsChanged;

  @override
  State<VachanamrutHomePage> createState() => _VachanamrutHomePageState();
}

class _VachanamrutHomePageState extends State<VachanamrutHomePage> {
  static const _widgetChannel = MethodChannel('vachanamrut_app/widget');
  late final WidgetSyncService _widgetSyncService = WidgetSyncService();

  late final Future<List<VachanamrutQuote>> _quotes = QuoteRepository.load();
  Future<void> _requestWidgetPin() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _showMessage(
        'Long-press your iPhone home screen, tap +, then add Vachanamrut Daily.',
      );
      return;
    }

    try {
      final pinned = await _widgetChannel.invokeMethod<bool>('requestPinWidget');
      if (!mounted) return;
      _showMessage(
        switch (defaultTargetPlatform) {
          TargetPlatform.android when pinned == true =>
            'Choose where to place the Vachanamrut widget.',
          TargetPlatform.android =>
            'Long-press your home screen and add the Vachanamrut widget.',
          _ => 'Long-press your home screen and add the Vachanamrut widget.',
        },
      );
    } on PlatformException catch (_) {
      if (!mounted) return;
      _showMessage(_manualWidgetInstallMessage());
    } on MissingPluginException catch (_) {
      if (!mounted) return;
      _showMessage(_manualWidgetInstallMessage());
    }
  }

  Future<void> _refreshWidgets() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _showMessage('iPhone widgets update automatically every hour.');
      return;
    }

    try {
      await _widgetSyncService.refreshWidgets();
      if (!mounted) return;
      _showMessage('Widgets refreshed.');
    } on PlatformException catch (_) {
      if (!mounted) return;
      _showMessage(_manualWidgetInstallMessage());
    } on MissingPluginException catch (_) {
      if (!mounted) return;
      _showMessage(_manualWidgetInstallMessage());
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsPage(
          settingsService: widget.settingsService,
          onSettingsChanged: widget.onSettingsChanged,
        ),
      ),
    );
    if (!mounted) return;
    await widget.onSettingsChanged?.call();
    setState(() {});
  }

  String _manualWidgetInstallMessage() {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'Long-press your iPhone home screen, tap +, then add Vachanamrut Daily.'
        : 'Long-press your home screen and add the Vachanamrut widget.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _intervalLabel(Duration interval) {
    if (interval.inMinutes % 60 == 0 && interval.inMinutes >= 60) {
      final hours = interval.inHours;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return '${interval.inMinutes} minutes';
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.settingsService.displayLanguage;
    final intervalLabel = _intervalLabel(widget.settingsService.quoteInterval);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vachanamrut Daily'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
          ),
          IconButton(
            onPressed: _refreshWidgets,
            tooltip: 'Refresh widgets',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<VachanamrutQuote>>(
        future: _quotes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final quotes = snapshot.data ?? const <VachanamrutQuote>[];
          if (quotes.isEmpty) {
            return const Center(child: Text('No quotes are available yet.'));
          }

          final currentQuote = _quoteForDate(DateTime.now(), quotes);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TodayPanel(quote: currentQuote, language: language),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Color(0xFFF58220)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rotation interval',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Quote changes every $intervalLabel',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              QuoteCard(
                quote: currentQuote,
                onAddWidget: _requestWidgetPin,
                displayLanguage: language,
              ),
            ],
          );
        },
      ),
    );
  }

  VachanamrutQuote _quoteForDate(DateTime date, List<VachanamrutQuote> quotes) {
    final interval = widget.settingsService.quoteInterval;
    final intervalIndex = date.millisecondsSinceEpoch ~/ interval.inMilliseconds;
    return quotes[intervalIndex % quotes.length];
  }
}
