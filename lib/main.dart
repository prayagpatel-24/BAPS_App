import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      home: const QuoteHomePage(),
    );
  }
}

class QuoteHomePage extends StatefulWidget {
  const QuoteHomePage({super.key});

  @override
  State<QuoteHomePage> createState() => _QuoteHomePageState();
}

class _QuoteHomePageState extends State<QuoteHomePage> {
  static const _widgetChannel = MethodChannel('vachanamrut_app/widget');

  late final Future<List<VachanamrutQuote>> _quotes = QuoteRepository.load();
  bool _showMeaningPreview = false;

  Future<void> _requestWidgetPin() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      _showMessage('Home-screen widgets are being tested on Android first.');
      return;
    }

    try {
      final pinned = await _widgetChannel.invokeMethod<bool>(
        'requestPinWidget',
      );
      if (!mounted) return;
      _showMessage(
        pinned == true
            ? 'Choose where to place the Vachanamrut widget.'
            : 'Long-press your home screen and add the Vachanamrut widget.',
      );
    } on PlatformException {
      if (!mounted) return;
      _showMessage(
        'Long-press your home screen and add the Vachanamrut widget.',
      );
    }
  }

  Future<void> _refreshWidgets() async {
    try {
      await _widgetChannel.invokeMethod<void>('refreshWidgets');
      if (!mounted) return;
      _showMessage('Widgets refreshed.');
    } on PlatformException {
      if (!mounted) return;
      _showMessage('Widget refresh is available after installing on Android.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vachanamrut Daily'),
        actions: [
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

          final currentQuote = quotes[DateTime.now().hour ~/ 4 % quotes.length];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _TodayPanel(quote: currentQuote),
              const SizedBox(height: 14),
              _WidgetPreviewCard(
                quote: currentQuote,
                showMeaning: _showMeaningPreview,
                onToggle: () {
                  setState(() {
                    _showMeaningPreview = !_showMeaningPreview;
                  });
                },
                onAddWidget: _requestWidgetPin,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TodayPanel extends StatelessWidget {
  const _TodayPanel({required this.quote});

  final VachanamrutQuote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF58220),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.reference,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      quote.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            quote.quote,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetPreviewCard extends StatelessWidget {
  const _WidgetPreviewCard({
    required this.quote,
    required this.showMeaning,
    required this.onToggle,
    required this.onAddWidget,
  });

  final VachanamrutQuote quote;
  final bool showMeaning;
  final VoidCallback onToggle;
  final VoidCallback onAddWidget;

  @override
  Widget build(BuildContext context) {
    final body = showMeaning ? quote.meaning : quote.quote;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.widgets_rounded, color: Color(0xFFF58220)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Widget Preview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAddWidget,
                  icon: const Icon(Icons.add_to_home_screen_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 154),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4EA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF5C99F)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showMeaning ? 'English Meaning' : quote.reference,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF8A4B12),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF2D241D),
                        fontWeight: FontWeight.w700,
                        height: 1.32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      showMeaning
                          ? 'Tap to return to Gujarati'
                          : 'Tap to see meaning',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF7D7067),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VachanamrutQuote {
  const VachanamrutQuote({
    required this.reference,
    required this.title,
    required this.quote,
    required this.meaning,
  });

  factory VachanamrutQuote.fromJson(Map<String, Object?> json) {
    return VachanamrutQuote(
      reference: json['reference'] as String,
      title: json['title'] as String,
      quote: json['quote'] as String,
      meaning: json['meaning'] as String,
    );
  }

  final String reference;
  final String title;
  final String quote;
  final String meaning;
}

class QuoteRepository {
  const QuoteRepository._();

  static Future<List<VachanamrutQuote>> load() async {
    final jsonText = await rootBundle.loadString(
      'assets/vachanamrut_quotes.json',
    );
    final decoded = jsonDecode(jsonText) as List<Object?>;
    return decoded
        .cast<Map<String, Object?>>()
        .map(VachanamrutQuote.fromJson)
        .toList(growable: false);
  }
}
