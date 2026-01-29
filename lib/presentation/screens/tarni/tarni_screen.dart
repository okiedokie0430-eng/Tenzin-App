import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tarni_provider.dart';

class _NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class TarniScreen extends ConsumerStatefulWidget {
  const TarniScreen({super.key});

  @override
  ConsumerState<TarniScreen> createState() => _TarniScreenState();
}

class _TarniScreenState extends ConsumerState<TarniScreen> {
  final _magController = TextEditingController();
  final _janController = TextEditingController();

  @override
  void dispose() {
    _magController.dispose();
    _janController.dispose();
    super.dispose();
  }

  Future<void> _addEntry() async {
    final mag = int.tryParse(_magController.text.trim()) ?? 0;
    final jan = int.tryParse(_janController.text.trim()) ?? 0;
    if (mag <= 0 && jan <= 0) return;
    await ref.read(tarniListProvider.notifier).add(mag, jan);
    _magController.clear();
    _janController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(tarniListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тарни тоолол'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        systemOverlayStyle: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed input area (not scrollable)
            const Text('УМ А РА БА ЗА НА ДИ', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _magController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Магзушир бурхны тоо',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            const Text('УМ МА НИ БАД МЭ ХУМ', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _janController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Жанрайсиг бурхны тоо',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final theme = Theme.of(context);
              return GestureDetector(
                onTap: _addEntry,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary, width: 2),
                    boxShadow: [
                      // single glow effect for the Add button
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.22),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Нэмэх',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),

            // Expandable list area (scrollable only)
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('Тоолол алга байна', style: Theme.of(context).textTheme.bodyMedium))
                  : ScrollConfiguration(
                      behavior: _NoGlowScrollBehavior(),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final entry = list[idx];
                          return Container(
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.08),
                              ),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Магзушир', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text('${entry.magzushirCount}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Жанрайсиг', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text('${entry.janraisigCount}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Сүүлд хадгалсан: ${entry.createdAt.toLocal()}'),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Засах'),
                                      onPressed: () async {
                                        final magController = TextEditingController(text: '${entry.magzushirCount}');
                                        final janController = TextEditingController(text: '${entry.janraisigCount}');
                                        final res = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Засах'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(controller: magController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Магзушир')),
                                                TextField(controller: janController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Жанрайсиг')),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Буцах')),
                                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Хадгалах')),
                                            ],
                                          ),
                                        );
                                        if (res == true) {
                                          final mag = int.tryParse(magController.text.trim()) ?? 0;
                                          final jan = int.tryParse(janController.text.trim()) ?? 0;
                                          await ref.read(tarniListProvider.notifier).updateEntry(entry.id, mag, jan);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Устгах'),
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Устгах'),
                                            content: const Text('Энэ бүртгэл устгах уу?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Буцах')),
                                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Устгах')),
                                            ],
                                          ),
                                        );
                                        if (ok == true) {
                                          await ref.read(tarniListProvider.notifier).remove(entry.id);
                                        }
                                      },
                                      style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
