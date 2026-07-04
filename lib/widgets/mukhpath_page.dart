import 'package:flutter/material.dart';

import '../models/mukhpath_item.dart';
import '../services/app_settings_service.dart';
import '../services/mukhpath_repository.dart';

class MukhpathPage extends StatefulWidget {
  const MukhpathPage({super.key, required this.settingsService});

  final AppSettingsService settingsService;

  @override
  State<MukhpathPage> createState() => _MukhpathPageState();
}

class _MukhpathPageState extends State<MukhpathPage> {
  late final List<MukhpathItem> _items = MukhpathRepository.loadSampleData();
  late final Set<String> _completedIds = widget.settingsService.completedMukhpathIds;
  final Map<String, bool> _revealedAnswers = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final visibleItems = _items.where((item) => !_completedIds.contains(item.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Mukhpath')),
      body: visibleItems.isEmpty
          ? _EmptyState(
              onReset: () async {
                await widget.settingsService.clearCompletedMukhpath();
                setState(() {
                  _completedIds.clear();
                });
              },
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visibleItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final revealed = _revealedAnswers[item.id] ?? false;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.question,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Checkbox(
                              value: _completedIds.contains(item.id),
                              onChanged: (value) async {
                                await widget.settingsService.toggleMukhpathCompletion(item.id);
                                setState(() {
                                  if (value == true) {
                                    _completedIds.add(item.id);
                                  } else {
                                    _completedIds.remove(item.id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _revealedAnswers[item.id] = !(revealed);
                            });
                          },
                          icon: Icon(revealed ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          label: Text(revealed ? 'Hide answer' : 'Reveal answer'),
                        ),
                        if (revealed) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4EA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.answer,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'All Mukhpath prompts are complete.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onReset, child: const Text('Reset progress')),
          ],
        ),
      ),
    );
  }
}
