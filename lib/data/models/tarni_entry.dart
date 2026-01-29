class TarniEntry {
  final String id;
  final String? userId;
  final int magzushirCount;
  final int janraisigCount;
  final DateTime createdAt;

  TarniEntry({
    required this.id,
    this.userId,
    required this.magzushirCount,
    required this.janraisigCount,
    required this.createdAt,
  });

      factory TarniEntry.fromMap(Map<String, dynamic> map) => TarniEntry(
        id: map['\$id'] ?? map['id'] ?? '',
        userId: map['userId'] as String?,
        magzushirCount: (map['magzushir'] as int?) ?? int.tryParse('${map['magzushir']}') ?? 0,
        janraisigCount: (map['janraisig'] as int?) ?? int.tryParse('${map['janraisig']}') ?? 0,
        createdAt: map['createdAt'] is int
        ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
        : DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
      if (userId != null) 'userId': userId,
        'magzushir': magzushirCount,
        'janraisig': janraisigCount,
        'createdAt': createdAt.toIso8601String(),
      };
}
