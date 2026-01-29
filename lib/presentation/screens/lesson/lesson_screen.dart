// =============================================================================
// LESSON SCREEN - REVAMPED
// =============================================================================
// CHANGES:
// - UI: New question flow prioritizing pronunciation over Tibetan script
// - UI: Added Fill-in-the-blank question type with block selection
// - UI: Added Matching/Connection question type
// - LOGIC: Advanced question types appear based on lesson progression
// - PERFORMANCE: Optimized animations, preloading for low-end devices
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../providers/lesson_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/heart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../widgets/common/heart_display.dart';
import '../../widgets/common/progress_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../achievements/achievement_unlock_presentation.dart';
import '../../../core/constants/app_colors.dart';
import '../streaks/streak_screen.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _xpEarned = 0;
  bool _isCompleted = false;
  String? _selectedAnswer;
  bool _showResult = false;

  // Matching question state
  String? _selectedLeftMatch;
  String? _selectedRightMatch;
  final Set<String> _matchedPairs = {};
  // Use computed pair keys (left||right) to avoid relying on external id types
  String _pairKey(String left, String right) => '$left|$right';
  bool _matchingComplete = false;
  bool _matchingFailed = false;
  String? _wrongLeft;
  String? _wrongRight;

  // Fill-in-blank state
  String? _filledAnswer;

  // Utility: normalize strings for robust comparisons (trim + collapse whitespace)
  String _normalize(String? s) => (s ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

  // Achievement unlock queue
  final List<String> _pendingAchievementIds = [];
  bool _showingAchievement = false;
  
  // Sound service removed — sounds are disabled
  // Cached shuffled options per question index to avoid reshuffling on rebuilds
  final Map<int, List<Map<String, dynamic>>> _shuffledOptionsByQuestion = {};

  // Animation controllers - optimized for low-end devices
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _completionController;
  late AnimationController _checkmarkController;
  late AnimationController _progressFillController;
  late AnimationController _matchAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _completionFadeAnimation;
  late Animation<double> _checkmarkAnimation;
  late Animation<double> _progressFillAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // Mark lesson as started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        ref
            .read(progressProvider.notifier)
            .startLesson(userId, widget.lessonId);
      }
    });
  }

  void _initAnimations() {
    // Fade animation for content - reduced duration for performance
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Slide animation for questions
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Scale animation for selection feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Completion screen animations
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _completionFadeAnimation = CurvedAnimation(
      parent: _completionController,
      curve: Curves.easeOut,
    );

    // Checkmark draw animation
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkmarkAnimation = CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.easeOutBack,
    );

    // Progress fill animation
    _progressFillController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressFillAnimation = CurvedAnimation(
      parent: _progressFillController,
      curve: Curves.easeOutCubic,
    );

    // Match animation controller
    _matchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Start initial animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _completionController.dispose();
    _checkmarkController.dispose();
    _progressFillController.dispose();
    _matchAnimationController.dispose();
    super.dispose();
  }

  void _animateToNextQuestion() async {
    // Clear state FIRST to prevent brief flash of correct answer
    setState(() {
      _selectedAnswer = null;
      _showResult = false;
      _filledAnswer = null;
      _selectedLeftMatch = null;
      _selectedRightMatch = null;
      _matchedPairs.clear();
      _matchingComplete = false;
    });

    await _fadeController.reverse();
    await _slideController.reverse();

    setState(() {
      _currentQuestionIndex++;
    });

    _fadeController.forward();
    _slideController.forward();
  }

  void _showNextAchievement() {
    if (_showingAchievement || _pendingAchievementIds.isEmpty) return;

    final achievementId = _pendingAchievementIds.removeAt(0);
    final achievements = ref.read(achievementProvider).achievements;
    final achievement = achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => achievements.first,
    );

    _showingAchievement = true;

    // Show achievement unlock presentation
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // Semi-transparent background
      builder: (context) => AchievementUnlockPresentation(
        achievement: achievement,
        onDismiss: () {
          // Do not pop here; the presentation will dismiss itself.
          _showingAchievement = false;
          // Show next achievement after a short delay
          Future.delayed(const Duration(milliseconds: 300), () {
            _showNextAchievement();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonDetail = ref.watch(lessonDetailProvider(widget.lessonId));
    final heartState = ref.watch(heartProvider);

    // Listen for achievement unlocks
    ref.listen<AchievementState>(achievementProvider, (previous, next) {
      if (next.newlyUnlocked.isNotEmpty) {
        // Queue newly unlocked achievements
        for (final achievement in next.newlyUnlocked) {
          if (!_pendingAchievementIds.contains(achievement.id)) {
            _pendingAchievementIds.add(achievement.id);
          }
        }
        // Show next achievement if not currently showing one
        _showNextAchievement();
        // Clear the newly unlocked list
        ref.read(achievementProvider.notifier).clearNewlyUnlocked();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _isCompleted
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _showExitDialog(),
              ),
              title: lessonDetail.when(
                data: (detail) => _buildBreadcrumb(detail),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: HeartDisplay(
                    currentHearts: heartState.hearts,
                    maxHearts: 5,
                  ),
                ),
              ],
            ),
      body: _isCompleted
          ? _buildCompletionScreen()
          : lessonDetail.when(
              data: (detail) {
                if (detail.lesson == null) {
                  return const Center(child: Text('Хичээл олдсонгүй'));
                }
                return _buildLessonContent(detail);
              },
              loading: () =>
                  const LoadingWidget(message: 'Хичээл ачааллаж байна...'),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Алдаа: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(lessonDetailProvider(widget.lessonId));
                      },
                      child: const Text('Дахин оролдох'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBreadcrumb(LessonDetailState detail) {
    final lesson = detail.lesson;
    if (lesson == null) return const SizedBox.shrink();

    final words = detail.lessonWithWords?.words ?? [];
    final leafWord = words.isNotEmpty ? words.last : null;
    final title = leafWord?.mongolianTranslation ?? lesson.title;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_outlined,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLessonContent(LessonDetailState detail) {
    final questions = detail.questions;
    if (questions.isEmpty) {
      return const Center(child: Text('Асуулт байхгүй байна'));
    }

    final currentQuestion = questions[_currentQuestionIndex];
    // Ensure options for this question are shuffled once and cached
    _ensureShuffledOptionsForQuestion(_currentQuestionIndex, currentQuestion);
    final progress = (_currentQuestionIndex + 1) / questions.length;
    final questionType = currentQuestion['type'] as String;

    // Determine whether the bottom action should be visible (slide up).
    // For matching questions we deliberately hide the bottom action UI entirely.
    bool isAnswered;
    if (questionType == 'matching') {
      isAnswered = false;
    } else if (questionType == 'fill_in_blank') {
      isAnswered = _filledAnswer != null;
    } else {
      isAnswered = _selectedAnswer != null;
    }

    final bottomSpacing = math.min(88.0, MediaQuery.of(context).size.height * 0.10);

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseWidth = 420.0;
        final widthScale = (constraints.maxWidth / baseWidth).clamp(0.75, 1.0);
        final textScale = MediaQuery.of(context).textScaleFactor * widthScale;
        final maxContentWidth = math.min(720.0, constraints.maxWidth * 0.95);

        final content = SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Stack(
            children: [
              Column(
                children: [
                  // Progress section
                  _buildProgressSection(progress, questions.length),
                  const SizedBox(height: 12),
                  // Question content based on type
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuestionByType(currentQuestion, questionType),
                    ),
                  ),
                  // keep adaptive space at bottom so content can scroll behind the button
                  SizedBox(height: bottomSpacing),
                ],
              ),
              // Sliding bottom action overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 280),
                  offset: isAnswered ? Offset.zero : const Offset(0, 1.4),
                  curve: Curves.easeOutCubic,
                  child: _buildBottomAction(currentQuestion, questionType),
                ),
              ),
            ],
              ),
            ),
          ),
        );

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: textScale),
              child: content,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSection(double progress, int totalQuestions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Асуулт ${_currentQuestionIndex + 1} / $totalQuestions', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
                        const SizedBox(width: 6),
                        Text(
                          '+$_xpEarned',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ProgressBar(
                progress: progress,
                height: 8,
                progressColor: AppColors.progressGreen,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // QUESTION TYPE BUILDERS
  // ==========================================================================

  Widget _buildQuestionByType(
      Map<String, dynamic> question, String questionType) {
    switch (questionType) {
      case 'pronunciation_to_mongolian':
        return _buildPronunciationToMongolianQuestion(question);
      case 'mongolian_to_pronunciation':
        return _buildMongolianToPronunciationQuestion(question);
      case 'fill_in_blank':
        return _buildFillInBlankQuestion(question);
      case 'matching':
        return _buildMatchingQuestion(question);
      // Legacy support
      case 'tibetan_character':
        return _buildPronunciationToMongolianQuestion(question);
      case 'meaning':
        return _buildMongolianToPronunciationQuestion(question);
      default:
        return _buildPronunciationToMongolianQuestion(question);
    }
  }

  // --------------------------------------------------------------------------
  // TYPE 1: Pronunciation → Mongolian Translation
  // Shows pronunciation prominently, small Tibetan below
  // --------------------------------------------------------------------------
  Widget _buildPronunciationToMongolianQuestion(Map<String, dynamic> question) {
    final phonetic = question['phonetic'] ?? question['correctAnswer'] ?? '';
    final tibetan = question['tibetanText'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question card with pronunciation focus
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Pronunciation - LARGE and prominent
              Text(
                phonetic,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      letterSpacing: 1,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Tibetan script - smaller, secondary
              if (tibetan.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tibetan,
                    style: const TextStyle(
                      fontFamily: 'NotoSansTibetan',
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              // Question text
              Text(
                question['question'] ?? 'Монгол утгыг сонгоно уу',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Answer options
        ..._buildAnswerOptions(question),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TYPE 2: Mongolian → Pronunciation
  // --------------------------------------------------------------------------
  Widget _buildMongolianToPronunciationQuestion(Map<String, dynamic> question) {
    final mongolian =
        question['mongolianText'] ?? question['correctAnswer'] ?? '';
    final tibetan = question['tibetanText'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.secondaryContainer,
                Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Mongolian text - prominent
              Text(
                mongolian,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                textAlign: TextAlign.center,
              ),
              if (tibetan.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  tibetan,
                  style: const TextStyle(
                    fontFamily: 'NotoSansTibetan',
                    fontSize: 20,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                question['question'] ?? 'Төвөд дуудлагыг сонгоно уу',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ..._buildAnswerOptions(question),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TYPE 3: Fill-in-the-Blank (Insert correct answer)
  // Shows blocks that user can tap to fill the blank
  // --------------------------------------------------------------------------
  Widget _buildFillInBlankQuestion(Map<String, dynamic> question) {
    final sentence = question['sentence'] ?? '';
    final options = (question['options'] as List?) ?? [];
    final phonetic = question['phonetic'] ?? '';
    final tibetan = question['tibetanText'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show Tibetan and phonetic if available
        if (tibetan.isNotEmpty || phonetic.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (tibetan.isNotEmpty)
                  Text(
                    tibetan,
                    style: const TextStyle(
                      fontFamily: 'NotoSansTibetan',
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (tibetan.isNotEmpty && phonetic.isNotEmpty)
                  const SizedBox(height: 8),
                if (phonetic.isNotEmpty)
                  Text(
                    phonetic,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),

        // Question header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              const SizedBox(height: 8),
              Text(
                'Хоосон зайг нөхөж бичнэ үү',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sentence with blank
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                  ),
              children: _buildSentenceWithBlank(sentence),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Block options for filling
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: options.map<Widget>((option) {
            final isSelected = _filledAnswer == option;
            final isCorrect = option == question['correctAnswer'];

            Color? bgColor;
            Color? borderColor;

            if (_showResult) {
              if (isCorrect) {
                bgColor = AppColors.success.withOpacity(0.2);
                borderColor = AppColors.success;
              } else if (isSelected && !isCorrect) {
                bgColor = AppColors.error.withOpacity(0.2);
                borderColor = AppColors.error;
              }
            } else if (isSelected) {
              bgColor = Theme.of(context).colorScheme.primary.withOpacity(0.2);
              borderColor = Theme.of(context).colorScheme.primary;
            }

            return GestureDetector(
              onTap: _showResult
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      setState(() => _filledAnswer = option);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor ??
                      Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor ??
                        Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  option,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<TextSpan> _buildSentenceWithBlank(String sentence) {
    final parts = sentence.split('_____');
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        // Add the blank or filled answer
        if (_filledAnswer != null) {
          spans.add(TextSpan(
            text: ' $_filledAnswer ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _showResult
                  ? (_filledAnswer ==
                          ref
                              .read(lessonDetailProvider(widget.lessonId))
                              .questions[_currentQuestionIndex]['correctAnswer']
                      ? AppColors.success
                      : AppColors.error)
                  : Theme.of(context).colorScheme.primary,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: ' ________ ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ));
        }
      }
    }
    return spans;
  }

  // --------------------------------------------------------------------------
  // TYPE 4: Matching/Connection Question
  // Left: 3 pronunciations, Right: 3 Mongolian translations
  // User matches them by selecting one from each side
  // --------------------------------------------------------------------------
  Widget _buildMatchingQuestion(Map<String, dynamic> question) {
    final pairs = (question['pairs'] as List?) ?? [];

    // Create left (pronunciations) and right (translations) lists
    final leftItems = pairs.map((p) => p['left'] as String).toList();
    final rightItems =
        List<String>.from(pairs.map((p) => p['right'] as String).toList())
          ..sort(); // Shuffle right side deterministically by sorting

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withOpacity(0.2),
                AppColors.primary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                question['question'] ?? 'Тохируулна уу',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Дуудлага болон утгыг холбоно уу',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Matching pairs - Two columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Pronunciations
            Expanded(
              child: Column(
                children: leftItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final pairLeft = pairs[index]['left'] as String;
                  final pairRight = pairs[index]['right'] as String;
                  final pairKey = _pairKey(pairLeft, pairRight);
                  final isMatched = _matchedPairs.contains(pairKey);
                  final isSelected = _selectedLeftMatch == item && !isMatched;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMatchItem(
                      item,
                      isLeft: true,
                      isSelected: isSelected,
                      isMatched: isMatched,
                      onTap: isMatched
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedLeftMatch = item;
                              });
                              _scaleController.forward().then((_) => _scaleController.reverse());
                              // Check match AFTER setState completes
                              Future.microtask(() => _checkMatch(pairs));
                            },
                    ),
                  );
                }).toList(),
              ),
            ),
            // Connection indicators
            SizedBox(
              width: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  leftItems.length,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.3),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            // Right column - Mongolian translations
            Expanded(
              child: Column(
                children: rightItems.map((item) {
                  final matchingPair = pairs.firstWhere(
                    (p) => _normalize(p['right'] as String) == _normalize(item),
                    orElse: () => {'id': ''},
                  );
                  final pairLeft = matchingPair['left'] as String? ?? '';
                  final pairRight = matchingPair['right'] as String? ?? '';
                  final pairKey = _pairKey(pairLeft, pairRight);
                  final isMatched = _matchedPairs.contains(pairKey);
                  final isSelected = _selectedRightMatch == item && !isMatched;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMatchItem(
                      item,
                      isLeft: false,
                      isSelected: isSelected,
                      isMatched: isMatched,
                      onTap: isMatched
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedRightMatch = item;
                              });
                              _scaleController.forward().then((_) => _scaleController.reverse());
                              // Check match AFTER setState completes
                              Future.microtask(() => _checkMatch(pairs));
                            },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),

        // Progress indicator
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: _matchedPairs.length / pairs.length,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(AppColors.success),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          '${_matchedPairs.length} / ${pairs.length} тохируулсан',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMatchItem(
    String text, {
    required bool isLeft,
    required bool isSelected,
    required bool isMatched,
    VoidCallback? onTap,
  }) {
    Color bgColor;
    Color borderColor;

    final isWrong = !isMatched && ((isLeft && text == _wrongLeft) || (!isLeft && text == _wrongRight));

    if (isMatched) {
      bgColor = AppColors.success.withOpacity(0.15);
      borderColor = AppColors.success;
    } else if (isWrong) {
      bgColor = AppColors.error.withOpacity(0.15);
      borderColor = AppColors.error;
    } else if (isSelected) {
      bgColor = Theme.of(context).colorScheme.primary.withOpacity(0.15);
      borderColor = Theme.of(context).colorScheme.primary;
    } else {
      bgColor = Theme.of(context).colorScheme.surfaceContainerLow;
      borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.2);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            if (isMatched)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
              ),
            Expanded(
              child: Text(
                text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected || isMatched ? FontWeight.w600 : null,
                      decoration: isMatched ? TextDecoration.lineThrough : null,
                      color: isMatched
                        ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5)
                        : isWrong
                          ? AppColors.error
                          : null,
                    ),
                textAlign: isLeft ? TextAlign.right : TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkMatch(List<dynamic> pairs) {
    if (_selectedLeftMatch == null || _selectedRightMatch == null) return;

    // Normalize selections for robust comparison
    final normLeft = _normalize(_selectedLeftMatch);
    final normRight = _normalize(_selectedRightMatch);

    // Find if the selected pair is correct using normalized comparison
    Map<String, dynamic>? found;
    for (final p in pairs) {
      final left = p['left'] as String? ?? '';
      final right = p['right'] as String? ?? '';
      if (_normalize(left) == normLeft && _normalize(right) == normRight) {
        found = p as Map<String, dynamic>;
        break;
      }
    }

    if (found != null) {
      // Correct match!
      HapticFeedback.mediumImpact();
      // sound disabled
      setState(() {
        _matchingFailed = false;
        _wrongLeft = null;
        _wrongRight = null;
        final left = (found?['left'] as String?) ?? '';
        final right = (found?['right'] as String?) ?? '';
        final key = _pairKey(left, right);
        _matchedPairs.add(key);
        _selectedLeftMatch = null;
        _selectedRightMatch = null;

        if (_matchedPairs.length == pairs.length) {
          _matchingComplete = true;
          _correctAnswers++;
          _xpEarned += 15; // Bonus XP for matching
        }
      });
    } else {
      // Wrong match - show red feedback, mark failed and allow retry
      HapticFeedback.heavyImpact();
      // sound disabled
      setState(() {
        _matchingFailed = true;
        _wrongLeft = _selectedLeftMatch;
        _wrongRight = _selectedRightMatch;
      });

      // Keep selection visible briefly to show red highlight, then clear selection
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _selectedLeftMatch = null;
          _selectedRightMatch = null;
          _wrongLeft = null;
          _wrongRight = null;
        });
      });
    }
  }

  void _resetMatchingAttempt() {
    setState(() {
      _matchedPairs.clear();
      _selectedLeftMatch = null;
      _selectedRightMatch = null;
      _matchingFailed = false;
      _wrongLeft = null;
      _wrongRight = null;
      _matchingComplete = false;
    });
  }

  // Ensure shuffled options are computed once per question and cached
  void _ensureShuffledOptionsForQuestion(
      int questionIndex, Map<String, dynamic> question) {
    if (_shuffledOptionsByQuestion.containsKey(questionIndex)) return;

    final options = (question['options'] as List?) ?? [];
    final indexedOptions = List<Map<String, dynamic>>.generate(
      options.length,
      (index) => {'option': options[index], 'index': index},
    );

    final random = math.Random(question.hashCode);
    indexedOptions.shuffle(random);

    _shuffledOptionsByQuestion[questionIndex] = indexedOptions;
  }

  // ==========================================================================
  // ANSWER OPTIONS (for standard question types)
  // ==========================================================================

  List<Widget> _buildAnswerOptions(Map<String, dynamic> question) {
    // Use cached shuffled options for current question index when available
    final indexedOptions = _shuffledOptionsByQuestion[_currentQuestionIndex] ??
        (question['options'] as List? ?? [])
            .asMap()
            .entries
            .map((e) => {'option': e.value, 'index': e.key})
            .toList();
    
    return List.generate(indexedOptions.length, (displayIndex) {
      final item = indexedOptions[displayIndex];
      final option = item['option'] as String;
      // originalIndex not currently used but preserved for potential future features
      // final originalIndex = item['index'] as int;
      final isSelected = _selectedAnswer == option;
      final isCorrect = option == question['correctAnswer'];

      Color? backgroundColor;
      Color? borderColor;
      IconData? trailingIcon;

      if (_showResult) {
        if (isCorrect) {
          backgroundColor = AppColors.success.withOpacity(0.15);
          borderColor = AppColors.success;
          trailingIcon = Icons.check_circle_rounded;
        } else if (isSelected && !isCorrect) {
          backgroundColor = AppColors.error.withOpacity(0.15);
          borderColor = AppColors.error;
          trailingIcon = Icons.cancel_rounded;
        }
      } else if (isSelected) {
        backgroundColor =
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5);
        borderColor = Theme.of(context).colorScheme.primary;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ScaleTransition(
          scale:
              isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showResult
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedAnswer = option);
                      _scaleController.forward().then((_) {
                        _scaleController.reverse();
                      });
                    },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color:
                      backgroundColor ?? Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor ??
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: isSelected || (_showResult && isCorrect) ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + displayIndex),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        option,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ),
                    if (_showResult && trailingIcon != null)
                      Icon(
                        trailingIcon,
                        color: isCorrect ? AppColors.success : AppColors.error,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ==========================================================================
  // BOTTOM ACTION BUTTON
  // ==========================================================================

  Widget _buildBottomAction(
      Map<String, dynamic> question, String questionType) {
    // Do not show a bottom action for matching questions — inline matching UI
    // handles selection and validation.
    if (questionType == 'matching') {
      return const SizedBox.shrink();
    }
    bool isAnswered;
    if (questionType == 'matching') {
      // Allow the button to be clickable when both sides are selected,
      // or when matching is already complete/failed.
      isAnswered = _matchingComplete || _matchingFailed ||
          (_selectedLeftMatch != null && _selectedRightMatch != null);
    } else if (questionType == 'fill_in_blank') {
      isAnswered = _filledAnswer != null;
    } else {
      isAnswered = _selectedAnswer != null;
    }

    // For matching, skip the check step
    final isMatchingReady = questionType == 'matching' && _matchingComplete;
    final isMatchingFailed = questionType == 'matching' && _matchingFailed;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: !isAnswered
                ? null
                : () {
                    if (questionType == 'matching') {
                      // If matching already completed or failed, use the
                      // existing flows. If both sides are selected, perform
                      // the match check.
                      if (isMatchingReady) {
                        _nextQuestion();
                      } else if (isMatchingFailed) {
                        _resetMatchingAttempt();
                      } else if (_selectedLeftMatch != null && _selectedRightMatch != null) {
                        // Use microtask to keep parity with tap behavior
                        Future.microtask(() => _checkMatch(question['pairs'] as List<dynamic>));
                      }
                    } else {
                      if (_showResult) {
                        _nextQuestion();
                      } else {
                        _checkAnswer();
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isMatchingFailed
                  ? AppColors.error
                  : (_showResult || isMatchingReady ? AppColors.success : null),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              isMatchingReady
                  ? 'Үргэлжлүүлэх'
                  : isMatchingFailed
                      ? 'Дахин оролдох'
                      : _showResult
                          ? 'Үргэлжлүүлэх'
                          : 'Шалгах',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // ANSWER CHECKING
  // ==========================================================================

  void _checkAnswer() {
    final questions = ref.read(lessonDetailProvider(widget.lessonId)).questions;
    final currentQuestion = questions[_currentQuestionIndex];
    final questionType = currentQuestion['type'] as String;

    bool isCorrect;
    if (questionType == 'fill_in_blank') {
      isCorrect = _filledAnswer == currentQuestion['correctAnswer'];
    } else {
      isCorrect = _selectedAnswer == currentQuestion['correctAnswer'];
    }

    setState(() {
      _showResult = true;
      if (isCorrect) {
        _correctAnswers++;
        _xpEarned += 10;
        HapticFeedback.mediumImpact();
        // sound disabled
      } else {
        HapticFeedback.heavyImpact();
        // sound disabled
        final userId = ref.read(currentUserProvider)?.id;
        if (userId != null) {
          ref.read(heartProvider.notifier).useHeart(userId);
        }
      }
    });
  }

  void _nextQuestion() {
    final questions = ref.read(lessonDetailProvider(widget.lessonId)).questions;

    if (_currentQuestionIndex < questions.length - 1) {
      _animateToNextQuestion();
    } else {
      _completeLesson();
    }
  }

  // ==========================================================================
  // LESSON COMPLETION
  // ==========================================================================

  void _completeLesson() async {
    final questions = ref.read(lessonDetailProvider(widget.lessonId)).questions;
    final user = ref.read(currentUserProvider);
    final heartState = ref.read(heartProvider);

    if (user == null) return;
    
    // Play completion sound
    // sound disabled

    await ref.read(progressProvider.notifier).completeLesson(
          userId: user.id,
          lessonId: widget.lessonId,
          correctAnswers: _correctAnswers,
          totalQuestions: questions.length,
          xpEarned: _xpEarned,
          heartsRemaining: heartState.hearts,
          timeSpentSeconds: 0,
        );

    if (_xpEarned > 0) {
      await ref.read(leaderboardProvider.notifier).addXp(
            userId: user.id,
            userName: user.displayName,
            profileImageUrl: user.avatarUrl,
            xpToAdd: _xpEarned,
          );
    }

    await ref.read(authProvider.notifier).updateUserStats(
          xpEarned: _xpEarned,
          lessonCompleted: true,
        );

    final prevStreak = user.currentStreakDays;
    await ref.read(authProvider.notifier).awardDailyStreakIfEligible();

    final progressState = ref.read(progressProvider);
    final updatedUser = ref.read(currentUserProvider);
    final currentStreak = updatedUser?.currentStreakDays ?? prevStreak;
    final totalXp = user.totalXp + _xpEarned;
    final lessonsCompleted = progressState.completedCount + 1;

    final lessonDetail = ref.read(lessonDetailProvider(widget.lessonId));
    final lessonTreePath = lessonDetail.lesson?.treePath;
    final totalQuestions = lessonDetail.questions.length;
    final isPerfectLesson =
        totalQuestions > 0 && _correctAnswers == totalQuestions;

    await ref.read(achievementProvider.notifier).checkAndUnlock(
          userId: user.id,
          currentStreak: currentStreak,
          totalXp: totalXp,
          lessonsCompleted: lessonsCompleted,
          completedTreePath: lessonTreePath,
          perfectLesson: isPerfectLesson,
        );

    setState(() {
      _isCompleted = true;
    });

    _completionController.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      _checkmarkController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _progressFillController.forward();
    });

    // If streak increased, show streak screen after completion animations
    if (currentStreak > prevStreak) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black54,
            builder: (_) => StreakScreen(streakDays: currentStreak),
          );
        } catch (_) {}
      });
    }

  }

  // ==========================================================================
  // COMPLETION SCREEN
  // ==========================================================================

  Widget _buildCompletionScreen() {
    final questions = ref.read(lessonDetailProvider(widget.lessonId)).questions;
    final accuracy = questions.isNotEmpty
        ? (_correctAnswers / questions.length * 100).toInt()
        : 0;
    final isPerfect = accuracy == 100;

    return SafeArea(
      child: FadeTransition(
        opacity: _completionFadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated celebration icon
                AnimatedBuilder(
                  animation: _checkmarkAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _checkmarkAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPerfect
                                ? [AppColors.gold, const Color(0xFFFFD54F)]
                                : [
                                    AppColors.success,
                                    AppColors.success.withOpacity(0.8)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isPerfect
                                      ? AppColors.gold
                                      : AppColors.success)
                                  .withOpacity(0.35),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isPerfect)
                              ...List.generate(
                                8,
                                (i) => Transform.rotate(
                                  angle: (i * math.pi / 4),
                                  child: Container(
                                    width: 2,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.0),
                                          Colors.white.withOpacity(
                                              0.4 * _checkmarkAnimation.value),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Icon(
                              isPerfect
                                  ? Icons.workspace_premium
                                  : Icons.check_rounded,
                              size: 70,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),

                // Title
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        isPerfect ? '✨ Гайхалтай! ✨' : 'Хичээл дууслаа!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isPerfect
                            ? 'Та бүх асуултыг зөв хариуллаа!'
                            : 'Маш сайн байна, үргэлжлүүлээрэй!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.4,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Stats cards
                AnimatedBuilder(
                  animation: _progressFillAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _progressFillAnimation.value,
                      child: Transform.translate(
                        offset:
                            Offset(0, 30 * (1 - _progressFillAnimation.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompletionStat(
                          context,
                          icon: Icons.star_rounded,
                          value: '+$_xpEarned',
                          label: 'XP',
                          color: AppColors.gold,
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
                        ),
                        _buildCompletionStat(
                          context,
                          icon: Icons.gps_fixed_rounded,
                          value: '$accuracy%',
                          label: 'Нарийвчлал',
                          color: accuracy >= 80
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
                        ),
                        _buildCompletionStat(
                          context,
                          icon: Icons.check_circle_rounded,
                          value: '$_correctAnswers/${questions.length}',
                          label: 'Зөв',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Primary CTA
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.9 + (0.1 * value),
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Үргэлжлүүлэх',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Retry option
                if (!isPerfect)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: TextButton(
                      onPressed: () {
                        _completionController.reset();
                        _checkmarkController.reset();
                        _progressFillController.reset();
                        _fadeController.reset();
                        _slideController.reset();

                        setState(() {
                          _currentQuestionIndex = 0;
                          _correctAnswers = 0;
                          _xpEarned = 0;
                          _isCompleted = false;
                          _selectedAnswer = null;
                          _showResult = false;
                          _filledAnswer = null;
                          _selectedLeftMatch = null;
                          _selectedRightMatch = null;
                          _matchedPairs.clear();
                          _shuffledOptionsByQuestion.clear();
                          _matchingComplete = false;
                        });

                        _fadeController.forward();
                        _slideController.forward();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Дахин хийх',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final w = MediaQuery.of(context).size.width;
        // Make dialog wider on larger screens by reducing horizontal inset
        final horizontalInset = math.max(12.0, w * 0.06);
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: horizontalInset, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Хичээлээс гарах уу?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                ),
              ),
            ],
          ),
          content: Text(
            'Хичээлийн явц хадгалагдахгүй. Та дахин эхлэх шаардлагатай болно.',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Үргэлжлүүлэх',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'Гарах',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
