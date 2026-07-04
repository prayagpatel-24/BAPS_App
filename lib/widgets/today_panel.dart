import 'package:flutter/material.dart';

import '../models/vachanamrut_quote.dart';
import '../services/app_settings_service.dart';

class TodayPanel extends StatelessWidget {
  const TodayPanel({super.key, required this.quote, required this.language});

  final VachanamrutQuote quote;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final displayText = switch (language) {
      AppLanguage.gujarati => quote.quote,
      AppLanguage.gujaratiWithEnglish => quote.quote,
      AppLanguage.english => quote.meaning,
    };

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
                child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
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
            displayText,
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
