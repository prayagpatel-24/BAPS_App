import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settingsService,
    this.onSettingsChanged,
  });

  final AppSettingsService settingsService;
  final VoidCallback? onSettingsChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Duration _quoteInterval;
  late Duration _mukhpathInterval;
  late AppLanguage _language;

  final _quoteOptions = <Duration>[
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(minutes: 45),
    const Duration(hours: 1),
    const Duration(hours: 3),
    const Duration(hours: 6),
    const Duration(hours: 12),
    const Duration(hours: 24),
  ];

  final _mukhpathOptions = <Duration>[
    const Duration(minutes: 5),
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(minutes: 45),
    const Duration(hours: 1),
    const Duration(hours: 3),
    const Duration(hours: 6),
    const Duration(hours: 12),
    const Duration(hours: 24),
  ];

  @override
  void initState() {
    super.initState();
    _quoteInterval = widget.settingsService.quoteInterval;
    _mukhpathInterval = widget.settingsService.mukhpathInterval;
    _language = widget.settingsService.displayLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Vachanamrut quote timing',
            child: DropdownButtonFormField<Duration>(
              initialValue: _quoteInterval,
              items: _quoteOptions
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(_formatDuration(option)),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _quoteInterval = value);
                await widget.settingsService.setQuoteInterval(value);
                widget.onSettingsChanged?.call();
              },
            ),
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            title: 'Mukhpath timing',
            child: DropdownButtonFormField<Duration>(
              initialValue: _mukhpathInterval,
              items: _mukhpathOptions
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(_formatDuration(option)),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _mukhpathInterval = value);
                await widget.settingsService.setMukhpathInterval(value);
                widget.onSettingsChanged?.call();
              },
            ),
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            title: 'Display language',
            child: DropdownButtonFormField<AppLanguage>(
              initialValue: _language,
              items: AppLanguage.values
                  .map(
                    (language) => DropdownMenuItem(
                      value: language,
                      child: Text(_languageLabel(language)),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _language = value);
                await widget.settingsService.setDisplayLanguage(value);
                widget.onSettingsChanged?.call();
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes % 60 == 0 && duration.inMinutes >= 60) {
      final hours = duration.inHours;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return '${duration.inMinutes} minutes';
  }

  String _languageLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.gujarati:
        return 'Gujarati';
      case AppLanguage.gujaratiWithEnglish:
        return 'Gujarati with English Translation';
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
