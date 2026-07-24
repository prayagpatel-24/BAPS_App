import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settingsService,
    this.onSettingsChanged,
  });

  final AppSettingsService settingsService;
  final Future<void> Function()? onSettingsChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _orange = Color(0xFFF58220);
  static const _deepOrange = Color(0xFF8A4B12);
  static const _cream = Color(0xFFFFFBF7);
  static const _softOrange = Color(0xFFFFF4EA);
  static const _border = Color(0xFFEADFD4);
  static const _muted = Color(0xFF7D7067);

  late Duration _quoteInterval;
  late Duration _mukhpathInterval;
  late AppLanguage _language;
  late AppMode _appMode;

  final _quoteOptions = <Duration>[
    const Duration(minutes: 1),
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
    _quoteInterval = _resolveDurationOption(
      widget.settingsService.quoteInterval,
      _quoteOptions,
    );
    _mukhpathInterval = _resolveDurationOption(
      widget.settingsService.mukhpathInterval,
      _mukhpathOptions,
    );
    _language = widget.settingsService.displayLanguage;
    _appMode = widget.settingsService.appMode;
  }

  Future<void> _setAppMode(AppMode mode) async {
    if (_appMode == mode) return;
    setState(() => _appMode = mode);
    await widget.settingsService.setModeToggle(mode == AppMode.mukhpath);
    await widget.onSettingsChanged?.call();
  }

  Future<void> _setQuoteInterval(Duration interval) async {
    setState(() => _quoteInterval = interval);
    await widget.settingsService.setQuoteInterval(interval);
    await widget.onSettingsChanged?.call();
  }

  Future<void> _setMukhpathInterval(Duration interval) async {
    setState(() => _mukhpathInterval = interval);
    await widget.settingsService.setMukhpathInterval(interval);
    await widget.onSettingsChanged?.call();
  }

  Future<void> _setLanguage(AppLanguage language) async {
    setState(() => _language = language);
    await widget.settingsService.setDisplayLanguage(language);
    await widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final activeInterval = _appMode == AppMode.mukhpath
        ? _mukhpathInterval
        : _quoteInterval;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), scrolledUnderElevation: 0),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _SettingsHero(
              appMode: _appMode,
              intervalLabel: _formatDuration(activeInterval),
              languageLabel: _languageLabel(_language),
            ),
            const SizedBox(height: 16),
            _SettingsPanel(
              icon: Icons.tune_rounded,
              title: 'Experience',
              subtitle: _appMode == AppMode.mukhpath
                  ? 'Mukhpath practice is active.'
                  : 'Daily Vachanamrut quotes are active.',
              child: _ModeSegmentedControl(
                selectedMode: _appMode,
                onChanged: (mode) => unawaited(_setAppMode(mode)),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _appMode == AppMode.mukhpath
                  ? _SettingsPanel(
                      key: const ValueKey('mukhpath-timing'),
                      icon: Icons.event_repeat_rounded,
                      title: 'Mukhpath Timing',
                      subtitle:
                          'Widget refreshes every ${_formatDuration(_mukhpathInterval)}.',
                      child: _SettingsDropdown<Duration>(
                        value: _mukhpathInterval,
                        items: _mukhpathOptions,
                        label: 'Refresh interval',
                        itemLabel: _formatDuration,
                        onChanged: (value) =>
                            unawaited(_setMukhpathInterval(value)),
                      ),
                    )
                  : _SettingsPanel(
                      key: const ValueKey('quote-timing'),
                      icon: Icons.schedule_rounded,
                      title: 'Quote Timing',
                      subtitle:
                          'Widget rotates every ${_formatDuration(_quoteInterval)}.',
                      child: _SettingsDropdown<Duration>(
                        value: _quoteInterval,
                        items: _quoteOptions,
                        label: 'Rotation interval',
                        itemLabel: _formatDuration,
                        onChanged: (value) =>
                            unawaited(_setQuoteInterval(value)),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _SettingsPanel(
              icon: Icons.translate_rounded,
              title: 'Display Language',
              subtitle: _languageSummary(_language),
              child: _SettingsDropdown<AppLanguage>(
                value: _language,
                items: AppLanguage.values,
                label: 'Language',
                itemLabel: _languageLabel,
                onChanged: (value) => unawaited(_setLanguage(value)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration _resolveDurationOption(Duration value, List<Duration> options) {
    if (options.contains(value)) {
      return value;
    }

    Duration? closest;
    var closestDelta = 0;

    for (final option in options) {
      final delta = (option.inMilliseconds - value.inMilliseconds).abs();
      if (closest == null || delta < closestDelta) {
        closest = option;
        closestDelta = delta;
      }
    }

    return closest ?? options.first;
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} seconds';
    }
    if (duration.inMinutes % 60 == 0 && duration.inMinutes >= 60) {
      final hours = duration.inHours;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    final minutes = duration.inMinutes;
    return minutes == 1 ? '1 minute' : '$minutes minutes';
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

  String _languageSummary(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'English meanings are shown first.';
      case AppLanguage.gujarati:
        return 'Gujarati text is shown first.';
      case AppLanguage.gujaratiWithEnglish:
        return 'Gujarati text includes English translation.';
    }
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.appMode,
    required this.intervalLabel,
    required this.languageLabel,
  });

  final AppMode appMode;
  final String intervalLabel;
  final String languageLabel;

  @override
  Widget build(BuildContext context) {
    final modeLabel = appMode == AppMode.mukhpath ? 'Mukhpath' : 'Vachanamrut';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _SettingsPageState._orange,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _SettingsPageState._orange.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                      'Vachanamrut Daily',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$modeLabel mode',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(icon: Icons.schedule_rounded, label: intervalLabel),
              _HeroPill(icon: Icons.translate_rounded, label: languageLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SettingsPageState._border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _SettingsPageState._softOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: _SettingsPageState._deepOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _SettingsPageState._muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ModeSegmentedControl extends StatelessWidget {
  const _ModeSegmentedControl({
    required this.selectedMode,
    required this.onChanged,
  });

  final AppMode selectedMode;
  final ValueChanged<AppMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _SettingsPageState._cream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SettingsPageState._border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSegment(
              icon: Icons.menu_book_rounded,
              title: 'Vachanamrut',
              subtitle: 'Daily quotes',
              selected: selectedMode == AppMode.vachanamrut,
              onTap: () => onChanged(AppMode.vachanamrut),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeSegment(
              icon: Icons.school_rounded,
              title: 'Mukhpath',
              subtitle: 'Practice',
              selected: selectedMode == AppMode.mukhpath,
              onTap: () => onChanged(AppMode.mukhpath),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : _SettingsPageState._deepOrange;
    final supporting = selected
        ? Colors.white.withValues(alpha: 0.78)
        : _SettingsPageState._muted;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _SettingsPageState._orange : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground, size: 22),
                const SizedBox(height: 5),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: supporting,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsDropdown<T> extends StatelessWidget {
  const _SettingsDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.itemLabel,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String label;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _SettingsPageState._cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _SettingsPageState._border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: _SettingsPageState._orange,
            width: 1.4,
          ),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );
  }
}
