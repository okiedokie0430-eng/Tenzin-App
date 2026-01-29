// Lesson model for Tibetan learning app

class LessonModel {
  final String id;
  final String title;
  final String? description;
  final String type; // alphabet, vocabulary, grammar, reading, listening, speaking, writing, culture
  final int sequenceOrder;
  final String treePath;
  final int wordCount;
  final int version;

  const LessonModel({
    required this.id,
    required this.title,
    this.description,
    this.type = 'vocabulary',
    required this.sequenceOrder,
    required this.treePath,
    required this.wordCount,
    this.version = 1,
  });

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Хичээл',
      description: map['description'] as String?,
      type: map['type'] as String? ?? 'vocabulary',
      sequenceOrder: map['sequence_order'] as int? ?? 0,
      treePath: map['tree_path'] as String? ?? '',
      wordCount: map['word_count'] as int? ?? 0,
      version: map['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'sequence_order': sequenceOrder,
      'tree_path': treePath,
      'word_count': wordCount,
      'version': version,
    };
  }

  LessonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    int? sequenceOrder,
    String? treePath,
    int? wordCount,
    int? version,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      treePath: treePath ?? this.treePath,
      wordCount: wordCount ?? this.wordCount,
      version: version ?? this.version,
    );
  }
}

class LessonWordModel {
  final String id;
  final String lessonId;
  final String? parentWordId;
  final int wordOrder;
  final String tibetanScript;
  final String phonetic;
  final String mongolianTranslation;
  final int version;

  const LessonWordModel({
    required this.id,
    required this.lessonId,
    this.parentWordId,
    required this.wordOrder,
    required this.tibetanScript,
    required this.phonetic,
    required this.mongolianTranslation,
    this.version = 1,
  });

  factory LessonWordModel.fromMap(Map<String, dynamic> map) {
    return LessonWordModel(
      id: map['id'] as String? ?? '',
      lessonId: map['lesson_id'] as String? ?? '',
      parentWordId: map['parent_word_id'] as String?,
      wordOrder: map['word_order'] as int? ?? 0,
      tibetanScript: map['tibetan_script'] as String? ?? '',
      phonetic: map['phonetic'] as String? ?? '',
      mongolianTranslation: map['mongolian_translation'] as String? ?? '',
      version: map['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'parent_word_id': parentWordId,
      'word_order': wordOrder,
      'tibetan_script': tibetanScript,
      'phonetic': phonetic,
      'mongolian_translation': mongolianTranslation,
      'version': version,
    };
  }

  LessonWordModel copyWith({
    String? id,
    String? lessonId,
    String? parentWordId,
    int? wordOrder,
    String? tibetanScript,
    String? phonetic,
    String? mongolianTranslation,
    int? version,
  }) {
    return LessonWordModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      parentWordId: parentWordId ?? this.parentWordId,
      wordOrder: wordOrder ?? this.wordOrder,
      tibetanScript: tibetanScript ?? this.tibetanScript,
      phonetic: phonetic ?? this.phonetic,
      mongolianTranslation: mongolianTranslation ?? this.mongolianTranslation,
      version: version ?? this.version,
    );
  }
}

class LessonWithWords {
  final LessonModel lesson;
  final List<LessonWordModel> words;

  const LessonWithWords({
    required this.lesson,
    required this.words,
  });
}
