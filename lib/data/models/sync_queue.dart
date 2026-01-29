class SyncQueueModel {
  final String id;
  final String tableName;
  final String recordId;
  final String operation; // 'insert', 'update', 'delete'
  final String payload; // JSON blob
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String? errorMessage;

  const SyncQueueModel({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.errorMessage,
  });

  factory SyncQueueModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueModel(
      id: map['id'] as String? ?? '',
      tableName: map['table_name'] as String? ?? '',
      recordId: map['record_id'] as String? ?? '',
      operation: map['operation'] as String? ?? 'insert',
      payload: map['payload'] as String? ?? '{}',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
      retryCount: map['retry_count'] as int? ?? 0,
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_attempt_at'] as int)
          : null,
      errorMessage: map['error_message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'payload': payload,
      'created_at': createdAt.millisecondsSinceEpoch,
      'retry_count': retryCount,
      'last_attempt_at': lastAttemptAt?.millisecondsSinceEpoch,
      'error_message': errorMessage,
    };
  }

  SyncQueueModel copyWith({
    String? id,
    String? tableName,
    String? recordId,
    String? operation,
    String? payload,
    DateTime? createdAt,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
  }) {
    return SyncQueueModel(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      recordId: recordId ?? this.recordId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get canRetry => retryCount < 10;
}
