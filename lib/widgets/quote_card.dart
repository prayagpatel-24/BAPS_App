import 'package:flutter/material.dart';

import '../models/vachanamrut_quote.dart';
import '../services/app_settings_service.dart';

class QuoteCard extends StatefulWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.onAddWidget,
    required this.displayLanguage,
  });

  final VachanamrutQuote quote;
  final VoidCallback onAddWidget;
  final AppLanguage displayLanguage;

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  bool _showEnglish = false;

  @override
  Widget build(BuildContext context) {
    final primaryText = _primaryText;
    final titleLabel = _titleLabel;
    final translationVisible = widget.displayLanguage == AppLanguage.gujaratiWithEnglish;

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
                  onPressed: widget.onAddWidget,
                  icon: const Icon(Icons.add_to_home_screen_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
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
                    titleLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF8A4B12),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    primaryText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF2D241D),
                      fontWeight: FontWeight.w700,
                      height: 1.32,
                    ),
                  ),
                  if (translationVisible) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showEnglish = !_showEnglish;
                        });
                      },
                      icon: Icon(
                        _showEnglish
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      label: Text(_showEnglish ? 'Hide English' : 'Show English'),
                    ),
                    if (_showEnglish) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.quote.meaning,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D241D),
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 14),
                  Text(
                    translationVisible
                        ? (_showEnglish
                            ? 'English translation is now visible.'
                            : 'Gujarati text is shown by default.')
                        : 'Preview is ready for the selected language.',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF7D7067),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _primaryText {
    switch (widget.displayLanguage) {
      case AppLanguage.english:
        return widget.quote.meaning;
      case AppLanguage.gujarati:
        return widget.quote.quote;
      case AppLanguage.gujaratiWithEnglish:
        return widget.quote.quote;
    }
  }

  String get _titleLabel {
    switch (widget.displayLanguage) {
      case AppLanguage.english:
        return 'English Meaning';
      case AppLanguage.gujarati:
        return widget.quote.reference;
      case AppLanguage.gujaratiWithEnglish:
        return widget.quote.reference;
    }
  }
}
