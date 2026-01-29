import '../../data/models/lesson.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../core/error/failures.dart';

class GetAllLessonsUseCase {
  final LessonRepository _repository;

  GetAllLessonsUseCase(this._repository);

  Future<({List<LessonModel> lessons, Failure? failure})> call({
    bool forceRefresh = false,
  }) {
    return _repository.getAllLessons(forceRefresh: forceRefresh);
  }
}

class GetLessonByIdUseCase {
  final LessonRepository _repository;

  GetLessonByIdUseCase(this._repository);

  Future<({LessonModel? lesson, Failure? failure})> call(String lessonId) {
    return _repository.getLessonById(lessonId);
  }
}

class GetLessonWithWordsUseCase {
  final LessonRepository _repository;

  GetLessonWithWordsUseCase(this._repository);

  Future<({LessonWithWords? lessonWithWords, Failure? failure})> call(
    String lessonId,
  ) {
    return _repository.getLessonWithWords(lessonId);
  }
}

class GetLessonWordsUseCase {
  final LessonRepository _repository;

  GetLessonWordsUseCase(this._repository);

  Future<({List<LessonWordModel> words, Failure? failure})> call(
    String lessonId,
  ) {
    return _repository.getLessonWords(lessonId);
  }
}

class GetLessonCountUseCase {
  final LessonRepository _repository;

  GetLessonCountUseCase(this._repository);

  Future<int> call() {
    return _repository.getLessonCount();
  }
}

class GetNextLessonUseCase {
  final LessonRepository _repository;

  GetNextLessonUseCase(this._repository);

  Future<LessonModel?> call(int currentOrderIndex) {
    return _repository.getNextLesson(currentOrderIndex);
  }
}

class GetPreviousLessonUseCase {
  final LessonRepository _repository;

  GetPreviousLessonUseCase(this._repository);

  Future<LessonModel?> call(int currentOrderIndex) {
    return _repository.getPreviousLesson(currentOrderIndex);
  }
}

// Note: SyncLessonsUseCase removed - lessons are LOCAL-ONLY content
// They are loaded from assets via LessonDataLoader, not synced from Appwrite
