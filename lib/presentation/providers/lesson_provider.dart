import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lesson.dart';
import '../../core/error/failures.dart';
import 'repository_providers.dart';

// Lessons State
class LessonsState {
  final List<LessonModel> lessons;
  final bool isLoading;
  final Failure? failure;

  const LessonsState({
    this.lessons = const [],
    this.isLoading = false,
    this.failure,
  });

  LessonsState copyWith({
    List<LessonModel>? lessons,
    bool? isLoading,
    Failure? failure,
  }) {
    return LessonsState(
      lessons: lessons ?? this.lessons,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }

  static const initial = LessonsState();
}

// Lessons Notifier
class LessonsNotifier extends StateNotifier<LessonsState> {
  final Ref _ref;
  bool _isDisposed = false;

  LessonsNotifier(this._ref) : super(LessonsState.initial) {
    loadLessons();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(LessonsState Function(LessonsState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> loadLessons({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    final repository = _ref.read(lessonRepositoryProvider);
    final result = await repository.getAllLessons(forceRefresh: forceRefresh);

    _safeUpdate((s) => s.copyWith(
          isLoading: false,
          lessons: result.lessons,
          failure: result.failure,
        ));
  }

  Future<void> refresh() async {
    await loadLessons(forceRefresh: true);
  }
}

// Lessons Provider
final lessonsProvider =
    StateNotifierProvider<LessonsNotifier, LessonsState>((ref) {
  return LessonsNotifier(ref);
});

// Single Lesson State
class LessonDetailState {
  final LessonWithWords? lessonWithWords;
  final bool isLoading;
  final Failure? failure;

  const LessonDetailState({
    this.lessonWithWords,
    this.isLoading = false,
    this.failure,
  });

  LessonDetailState copyWith({
    LessonWithWords? lessonWithWords,
    bool? isLoading,
    Failure? failure,
  }) {
    return LessonDetailState(
      lessonWithWords: lessonWithWords ?? this.lessonWithWords,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }

  // Convenience getters
  LessonModel? get lesson => lessonWithWords?.lesson;
  List<Map<String, dynamic>> get questions => _generateQuestionsFromWords();

  /// Generates questions from the lesson words for quiz
  /// NEW FLOW:
  /// 1. Pronunciation → Mongolian (pronunciation is primary, show small Tibetan)
  /// 2. Mongolian → Pronunciation
  /// 3. Fill-in-the-blank (after 2-3 words)
  /// 4. Matching (after 50% of lesson, near end)
  List<Map<String, dynamic>> _generateQuestionsFromWords() {
    if (lessonWithWords == null || lessonWithWords!.words.isEmpty) {
      return [];
    }

    final words = lessonWithWords!.words;
    final questions = <Map<String, dynamic>>[];
    final lessonSequence = lessonWithWords!.lesson.sequenceOrder;

    // Higher lesson = higher chance of advanced question types
    // Lesson 1 = 0%, Lesson 10+ = 50% chance
    final advancedChance = (lessonSequence / 20).clamp(0.0, 0.5);

    for (int i = 0; i < words.length; i++) {
      final word = words[i];

      // QUESTION TYPE 1: Pronunciation → Mongolian translation
      // Shows pronunciation prominently, small Tibetan script below
      questions.add({
        'id': '${word.id}_pron_to_mn',
        'type': 'pronunciation_to_mongolian',
        'tibetanText': word.tibetanScript,
        'phonetic': word.phonetic,
        'question': 'Дуудлага "${word.phonetic}" -н монгол утга юу вэ?',
        'correctAnswer': word.mongolianTranslation,
        'options': _generateOptions(word.mongolianTranslation,
            words.map((w) => w.mongolianTranslation).toList()),
      });

      // QUESTION TYPE 2: Mongolian → Pronunciation
      questions.add({
        'id': '${word.id}_mn_to_pron',
        'type': 'mongolian_to_pronunciation',
        'tibetanText': word.tibetanScript,
        'mongolianText': word.mongolianTranslation,
        'question':
            '"${word.mongolianTranslation}" гэдгийн Төвөд дуудлага юу вэ?',
        'correctAnswer': word.phonetic,
        'options': _generateOptions(
            word.phonetic, words.map((w) => w.phonetic).toList()),
      });

      // QUESTION TYPE 3: Fill-in-the-blank (insert correct answer)
      // Appears after 2-3 words completed, based on lesson level
      if (i >= 2 && _shouldShowAdvancedQuestion(advancedChance, i)) {
        questions.add({
          'id': '${word.id}_fill_blank',
          'type': 'fill_in_blank',
          'tibetanText': word.tibetanScript,
          'phonetic': word.phonetic,
          'question': 'Зөв утгыг сонгоно уу',
          'sentence': '${word.phonetic} гэдгийн утга нь _____ юм.',
          'correctAnswer': word.mongolianTranslation,
          'options': _generateOptions(word.mongolianTranslation,
              words.map((w) => w.mongolianTranslation).toList()),
        });
      }
    }

    // QUESTION TYPE 4: Matching (connection) - appears after 50% of lesson
    // Only add if we have at least 3 words
    if (words.length >= 3 && advancedChance > 0.1) {
      // Take 3 random words for matching
      final matchWords = words.length <= 3 ? words : words.sublist(0, 3);

      questions.add({
        'id': 'matching_${lessonWithWords!.lesson.id}',
        'type': 'matching',
        'question': 'Дуудлага болон утгыг тохируулна уу',
        'pairs': matchWords
            .map((w) => {
                  'id': w.id,
                  'left': w.phonetic,
                  'right': w.mongolianTranslation,
                  'tibetan': w.tibetanScript,
                })
            .toList(),
      });
    }

    return questions;
  }

  /// Determines if an advanced question type should appear
  bool _shouldShowAdvancedQuestion(double chance, int wordIndex) {
    // Use deterministic "randomness" based on word index
    return (wordIndex % 3 == 0) && chance > 0.1;
  }

  List<String> _generateOptions(String correct, List<String> allOptions) {
    final options = <String>[correct];
    // Use deterministic ordering - sort alphabetically then take first 3 that differ from correct
    final sortedOthers = List<String>.from(allOptions)
      ..removeWhere((o) => o == correct)
      ..sort();
    for (final option in sortedOthers) {
      if (!options.contains(option) && options.length < 4) {
        options.add(option);
      }
      if (options.length >= 4) break;
    }
    // Pad with deterministic dummy options if needed
    final dummies = ['Сонголт А', 'Сонголт Б', 'Сонголт В', 'Сонголт Г'];
    int dummyIndex = 0;
    while (options.length < 4 && dummyIndex < dummies.length) {
      if (!options.contains(dummies[dummyIndex])) {
        options.add(dummies[dummyIndex]);
      }
      dummyIndex++;
    }
    // Sort options deterministically - correct answer first, then alphabetically
    options.sort((a, b) {
      if (a == correct) return -1;
      if (b == correct) return 1;
      return a.compareTo(b);
    });
    return options;
  }

  /// Pattern matching style method for async state handling
  T when<T>({
    required T Function(LessonDetailState) data,
    required T Function() loading,
    required T Function(Object error, StackTrace? stackTrace) error,
  }) {
    if (isLoading) {
      return loading();
    }
    if (failure != null) {
      return error(failure!.message, null);
    }
    return data(this);
  }
}

// Lesson Detail Notifier
class LessonDetailNotifier extends StateNotifier<LessonDetailState> {
  final Ref _ref;
  final String lessonId;
  bool _isDisposed = false;

  LessonDetailNotifier(this._ref, this.lessonId)
      : super(const LessonDetailState()) {
    loadLesson();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(LessonDetailState Function(LessonDetailState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> loadLesson() async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    final repository = _ref.read(lessonRepositoryProvider);
    final result = await repository.getLessonWithWords(lessonId);

    _safeUpdate((s) => s.copyWith(
          isLoading: false,
          lessonWithWords: result.lessonWithWords,
          failure: result.failure,
        ));
  }
}

// Lesson Detail Provider Family
final lessonDetailProvider = StateNotifierProvider.family<LessonDetailNotifier,
    LessonDetailState, String>((ref, lessonId) {
  return LessonDetailNotifier(ref, lessonId);
});

// Convenience providers
final lessonsListProvider = Provider<List<LessonModel>>((ref) {
  return ref.watch(lessonsProvider).lessons;
});

final isLessonsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(lessonsProvider).isLoading;
});

final lessonCountProvider = Provider<int>((ref) {
  return ref.watch(lessonsProvider).lessons.length;
});

/// Provider for all words in the dictionary
/// Returns unique lesson words for the dictionary screen (deduplicated)
final allWordsProvider = FutureProvider<List<LessonWordModel>>((ref) async {
  final repository = ref.read(lessonRepositoryProvider);
  return await repository.getUniqueWordsForDictionary();
});
