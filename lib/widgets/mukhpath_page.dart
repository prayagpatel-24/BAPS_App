import 'package:flutter/material.dart';

import '../models/mukhpath_item.dart';
import '../services/app_settings_service.dart';
import '../services/mukhpath_repository.dart';

class MukhpathPage extends StatefulWidget {
  const MukhpathPage({
    super.key,
    required this.settingsService,
    this.onStateChanged,
  });

  final AppSettingsService settingsService;
  final Future<void> Function()? onStateChanged;

  @override
  State<MukhpathPage> createState() => _MukhpathPageState();
}

class _MukhpathPageState extends State<MukhpathPage> {
  late final List<MukhpathItem> items = MukhpathRepository.loadSampleData();
  late final Set<String> completedIds = widget.settingsService.completedMukhpathIds;
  final Map<String, bool> revealedAnswers = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => !completedIds.contains(item.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Mukhpath')),
      body: visibleItems.isEmpty
          ? _EmptyState(
              onReset: () async {
                await widget.settingsService.clearCompletedMukhpath();
                setState(() {
                  completedIds.clear();
                });
                await widget.onStateChanged?.call();
              },
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visibleItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final revealed = revealedAnswers[item.id] ?? false;
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
                              value: completedIds.contains(item.id),
                              onChanged: (value) async {
                                await widget.settingsService.toggleMukhpathCompletion(item.id);
                                setState(() {
                                  if (value == true) {
                                    completedIds.add(item.id);
                                  } else {
                                    completedIds.remove(item.id);
                                  }
                                });
                                await widget.onStateChanged?.call();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              revealedAnswers[item.id] = !revealed;
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
