import 'user.dart';

enum SupportMessageStatus { open, responded, closed }

class SupportMessageModel {
  final String id;
  final String odUserId;
  final String message;
  final DateTime createdAt;
  final String? adminResponse;
  final DateTime? respondedAt;
  final SupportMessageStatus status;
  final SyncStatus syncStatus;
  final String? appwriteMessageId;

  const SupportMessageModel({
    required this.id,
    required this.odUserId,
    required this.message,
    required this.createdAt,
    this.adminResponse,
    this.respondedAt,
    this.status = SupportMessageStatus.open,
    this.syncStatus = SyncStatus.pending,
    this.appwriteMessageId,
  });

  factory SupportMessageModel.fromMap(Map<String, dynamic> map) {
    return SupportMessageModel(
      id: map['id'] as String? ?? '',
      odUserId: map['user_id'] as String? ?? '',
      message: map['message'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
      adminResponse: map['admin_response'] as String?,
      respondedAt: map['responded_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['responded_at'] as int)
          : null,
      status: SupportMessageStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'open'),
        orElse: () => SupportMessageStatus.open,
      ),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == (map['sync_status'] as String? ?? 'pending'),
        orElse: () => SyncStatus.pending,
      ),
      appwriteMessageId: map['appwrite_message_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': odUserId,
      'message': message,
      'created_at': createdAt.millisecondsSinceEpoch,
      'admin_response': adminResponse,
      'responded_at': respondedAt?.millisecondsSinceEpoch,
      'status': status.name,
      'sync_status': syncStatus.name,
      'appwrite_message_id': appwriteMessageId,
    };
  }

  SupportMessageModel copyWith({
    String? id,
    String? odUserId,
    String? message,
    DateTime? createdAt,
    String? adminResponse,
    DateTime? respondedAt,
    SupportMessageStatus? status,
    SyncStatus? syncStatus,
    String? appwriteMessageId,
  }) {
    return SupportMessageModel(
      id: id ?? this.id,
      odUserId: odUserId ?? this.odUserId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      appwriteMessageId: appwriteMessageId ?? this.appwriteMessageId,
    );
  }

  bool get hasResponse => adminResponse != null && adminResponse!.isNotEmpty;

  /// Check if this message is from the user (not admin response)
  /// User messages have no admin response flag set
  bool get isFromUser => adminResponse == null;

  /// Get the content of the message
  /// For user messages, return the message
  /// For admin responses, return the admin response
  String get content => message;

  /// Placeholder for image URL - currently not implemented
  String? get imageUrl => null;
}
