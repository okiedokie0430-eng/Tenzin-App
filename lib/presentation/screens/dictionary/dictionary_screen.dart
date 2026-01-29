import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/lesson.dart';
import '../../providers/lesson_provider.dart';
import 'word_detail_sheet.dart';

/// Dictionary Screen
/// 
/// Per ARCHITECTURE.md specs:
/// - List of all words (card buttons)
/// - Search bar
/// - Image gallery icon (top-right header)
/// - Tap word → show full tree path (root to selected word)
/// - Path displayed vertically, clearly showing hierarchy
class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(allWordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Толь бичиг'),
        centerTitle: true,
        actions: [
          // Image gallery icon
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/gallery');
            },
            tooltip: 'Зураг хадгалах',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Үг хайх...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          // Word list
          Expanded(
            child: wordsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Алдаа гарлаа: $error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allWordsProvider),
                      child: const Text('Дахин оролдох'),
                    ),
                  ],
                ),
              ),
              data: (words) {
                // Filter words by search query
                final filteredWords = _searchQuery.isEmpty
                    ? words
                    : words.where((word) {
                        return word.mongolianTranslation.toLowerCase().contains(_searchQuery) ||
                            word.phonetic.toLowerCase().contains(_searchQuery) ||
                            word.tibetanScript.contains(_searchQuery);
                      }).toList();

                // Group words by first letter of Mongolian translation
                final groupedWords = _groupWordsByFirstLetter(filteredWords);
                final sortedKeys = groupedWords.keys.toList()..sort();

                if (filteredWords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Үг байхгүй'
                              : 'Хайлтын үр дүн олдсонгүй',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, sectionIndex) {
                    final letter = sortedKeys[sectionIndex];
                    final sectionWords = groupedWords[letter]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            letter,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        // Words in this section
                        ...sectionWords.map((word) => _WordCard(
                              word: word,
                              onTap: () => _showWordDetail(context, word, words),
                            )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<LessonWordModel>> _groupWordsByFirstLetter(List<LessonWordModel> words) {
    final Map<String, List<LessonWordModel>> grouped = {};
    
    for (final word in words) {
      final firstLetter = word.mongolianTranslation.isNotEmpty
          ? word.mongolianTranslation[0].toUpperCase()
          : '#';
      
      grouped.putIfAbsent(firstLetter, () => []).add(word);
    }
    
    // Sort words within each group
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => 
        a.mongolianTranslation.compareTo(b.mongolianTranslation));
    }
    
    return grouped;
  }

  void _showWordDetail(
    BuildContext context, 
    LessonWordModel word, 
    List<LessonWordModel> allWords,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WordDetailSheet(
        word: word,
        allWords: allWords,
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final LessonWordModel word;
  final VoidCallback onTap;

  const _WordCard({
    required this.word,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Word info - only Mongolian translation and phonetic
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.mongolianTranslation,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.phonetic,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
