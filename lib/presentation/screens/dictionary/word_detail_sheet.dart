import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/lesson.dart';
import '../../../data/services/lesson_data_loader.dart';

/// Word Detail Sheet
/// 
/// Per ARCHITECTURE.md specs:
/// - When user taps a word in the dictionary
/// - Show full tree path (root to selected word)
/// - Path displayed vertically, clearly showing hierarchy
/// - Each node in path shows: Tibetan + phonetic + Mongolian
class WordDetailSheet extends StatefulWidget {
  final LessonWordModel word;
  final List<LessonWordModel> allWords;

  const WordDetailSheet({
    super.key,
    required this.word,
    required this.allWords,
  });

  @override
  State<WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<WordDetailSheet> {
  List<_WordPathNode>? _path;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPath();
  }

  Future<void> _loadPath() async {
    final path = await _buildWordPathFromJson(widget.word);
    if (mounted) {
      setState(() {
        _path = path;
        _isLoading = false;
      });
    }
  }

  /// Build the path from root to the selected word using original JSON data
  Future<List<_WordPathNode>> _buildWordPathFromJson(LessonWordModel targetWord) async {
    try {
      final originalWords = await LessonDataLoader.getOriginalWords();
      
      // Find the original word by matching tibetan_script and mongolian_translation
      Map<String, dynamic>? findOriginalWord(LessonWordModel word) {
        for (final ow in originalWords) {
          if (ow['tibetan_script'] == word.tibetanScript &&
              ow['mongolian_translation'] == word.mongolianTranslation) {
            return ow;
          }
        }
        return null;
      }

      final List<_WordPathNode> path = [];
      Map<String, dynamic>? current = findOriginalWord(targetWord);
      
      // Build path by following parent references in JSON
      while (current != null) {
        path.insert(0, _WordPathNode(
          tibetanScript: current['tibetan_script'] as String,
          phonetic: current['phonetic'] as String,
          mongolianTranslation: current['mongolian_translation'] as String,
          isTarget: current['tibetan_script'] == targetWord.tibetanScript &&
                   current['mongolian_translation'] == targetWord.mongolianTranslation,
        ));
        
        final parentId = current['parent_word_id'] as String?;
        if (parentId == null) {
          break;
        }
        
        current = originalWords.firstWhereOrNull(
          (w) => w['id'] == parentId,
        );
      }
      
      return path;
    } catch (e) {
      // Fallback to just showing the selected word
      return [
        _WordPathNode(
          tibetanScript: targetWord.tibetanScript,
          phonetic: targetWord.phonetic,
          mongolianTranslation: targetWord.mongolianTranslation,
          isTarget: true,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Үгийн зам',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Path visualization
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _path == null || _path!.isEmpty
                        ? const Center(child: Text('Зам олдсонгүй'))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _path!.length,
                            itemBuilder: (context, index) {
                              final pathNode = _path![index];
                              final isLast = index == _path!.length - 1;

                              return _PathNodeWidget(
                                node: pathNode,
                                isLast: isLast,
                                index: index,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Word path node data
class _WordPathNode {
  final String tibetanScript;
  final String phonetic;
  final String mongolianTranslation;
  final bool isTarget;

  const _WordPathNode({
    required this.tibetanScript,
    required this.phonetic,
    required this.mongolianTranslation,
    required this.isTarget,
  });
}

class _PathNodeWidget extends StatelessWidget {
  final _WordPathNode node;
  final bool isLast;
  final int index;

  const _PathNodeWidget({
    required this.node,
    required this.isLast,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = node.isTarget;
    
    return Column(
      children: [
        // Node with word info
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tibetan script
              Text(
                node.tibetanScript,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : null,
                    ),
              ),
              const SizedBox(height: 8),
              // Phonetic
              Text(
                node.phonetic,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              // Mongolian translation in brackets
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '[${node.mongolianTranslation}]',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
        // Arrow connector (if not last)
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 24,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Extension for firstWhereOrNull
extension _ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
