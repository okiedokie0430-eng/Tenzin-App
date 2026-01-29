import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';

import '../local/database_helper.dart';
import '../local/daos/sync_queue_dao.dart';
import '../models/sync_queue.dart';
import '../../core/utils/logger.dart';
import '../../core/platform/network_info.dart';
import 'appwrite_client.dart';

/// Supported sync table types
enum SyncTable {
  userProgress,
  lessonProgress,
  achievements,
  follows,
  notifications,
  messages,
  supportTickets,
  settings,
}

/// Sync operation types
enum SyncOperation {
  insert,
  update,
  delete,
}

/// Sync engine for offline-first data synchronization
class SyncEngine {
  final AppwriteClient _appwrite;
  final DatabaseHelper _dbHelper;
  final SyncQueueDao _syncQueueDao;
  final NetworkInfo _networkInfo;

  Timer? _syncTimer;
  bool _isSyncing = false;
  final _syncController = StreamController<SyncStatus>.broadcast();
  
  Stream<SyncStatus> get syncStatus => _syncController.stream;
  
  static const int _maxRetries = 5;
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _retryDelay = Duration(seconds: 30);

  SyncEngine({
    required AppwriteClient appwrite,
    required DatabaseHelper dbHelper,
    required SyncQueueDao syncQueueDao,
    required NetworkInfo networkInfo,
  })  : _appwrite = appwrite,
        _dbHelper = dbHelper,
        _syncQueueDao = syncQueueDao,
        _networkInfo = networkInfo;

  /// Start automatic sync
  void startAutoSync() {
    AppLogger.info('Starting auto-sync engine');
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) => sync());
    // Perform initial sync
    sync();
  }

  /// Stop automatic sync
  void stopAutoSync() {
    AppLogger.info('Stopping auto-sync engine');
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Queue an item for sync
  Future<void> queueForSync({
    required SyncTable table,
    required String recordId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    final item = SyncQueueModel(
      id: '${table.name}_${recordId}_${DateTime.now().millisecondsSinceEpoch}',
      tableName: table.name,
      recordId: recordId,
      operation: operation.name,
      payload: jsonEncode(data),
      createdAt: DateTime.now(),
    );

    await _syncQueueDao.insert(item);
    AppLogger.info('Queued ${operation.name} for ${table.name}:$recordId');

    // Try to sync immediately if online
    if (await _networkInfo.isConnected) {
      sync();
    }
  }

  /// Perform sync
  Future<SyncResult> sync() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        itemsSynced: 0,
        itemsFailed: 0,
      );
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      _syncController.add(SyncStatus.offline);
      return SyncResult(
        success: false,
        message: 'No network connection',
        itemsSynced: 0,
        itemsFailed: 0,
      );
    }

    _isSyncing = true;
    _syncController.add(SyncStatus.syncing);
    
    int synced = 0;
    int failed = 0;

    try {
      // Get pending items
      final pendingItems = await _syncQueueDao.getPendingItems(limit: 100);
      
      // Get items for retry
      final retryItems = await _syncQueueDao.getItemsForRetry(
        maxRetries: _maxRetries,
        minDelay: _retryDelay,
      );

      final allItems = [...pendingItems, ...retryItems];
      
      if (allItems.isEmpty) {
        _syncController.add(SyncStatus.synced);
        _isSyncing = false;
        return SyncResult(
          success: true,
          message: 'No items to sync',
          itemsSynced: 0,
          itemsFailed: 0,
        );
      }

      AppLogger.info('Syncing ${allItems.length} items');

      for (final item in allItems) {
        try {
          await _syncItem(item);
          await _syncQueueDao.markAsCompleted(int.parse(item.id.split('_').last));
          synced++;
        } catch (e) {
          AppLogger.error('Sync failed for ${item.tableName}:${item.recordId}', error: e);
          await _syncQueueDao.markAsFailed(
            int.parse(item.id.split('_').last),
            e.toString(),
          );
          failed++;
        }
      }

      // Clean up old completed items
      await _syncQueueDao.deleteOldCompleted(daysOld: 7);

      _syncController.add(SyncStatus.synced);
      AppLogger.info('Sync completed: $synced synced, $failed failed');

      return SyncResult(
        success: failed == 0,
        message: 'Sync completed',
        itemsSynced: synced,
        itemsFailed: failed,
      );
    } catch (e) {
      AppLogger.error('Sync error', error: e);
      _syncController.add(SyncStatus.error);
      return SyncResult(
        success: false,
        message: e.toString(),
        itemsSynced: synced,
        itemsFailed: failed,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncItem(SyncQueueModel item) async {
    final databases = Databases(_appwrite.client);
    final data = jsonDecode(item.payload) as Map<String, dynamic>;
    data.remove('id'); // Remove id as Appwrite uses documentId separately
    
    final collectionId = _getCollectionId(item.tableName);
    final databaseId = AppwriteClient.databaseId;

    switch (item.operation) {
      case 'insert':
        await databases.createDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: item.recordId,
          data: data,
        );
        break;
      case 'update':
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: item.recordId,
          data: data,
        );
        break;
      case 'delete':
        await databases.deleteDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: item.recordId,
        );
        break;
    }
  }

  String _getCollectionId(String tableName) {
    final mapping = {
      'userProgress': 'user_progress',
      'lessonProgress': 'lesson_progress',
      'achievements': 'user_achievements',
      'follows': 'follows',
      'notifications': 'notifications',
      'messages': 'messages',
      'supportTickets': 'support_tickets',
      'settings': 'user_settings',
    };
    return mapping[tableName] ?? tableName;
  }

  /// Pull latest data from server
  Future<void> pullFromServer(String userId) async {
    if (!await _networkInfo.isConnected) return;

    AppLogger.info('Pulling data from server for user: $userId');
    _syncController.add(SyncStatus.syncing);

    try {
      final databases = Databases(_appwrite.client);
      const databaseId = 'tenzin_db';

      // Pull user progress
      await _pullCollection(
        databases,
        databaseId,
        'user_progress',
        userId,
      );

      // Pull lesson progress
      await _pullCollection(
        databases,
        databaseId,
        'lesson_progress',
        userId,
      );

      // Pull achievements
      await _pullCollection(
        databases,
        databaseId,
        'user_achievements',
        userId,
      );

      // Pull notifications
      await _pullCollection(
        databases,
        databaseId,
        'notifications',
        userId,
      );

      _syncController.add(SyncStatus.synced);
      AppLogger.info('Pull from server completed');
    } catch (e) {
      AppLogger.error('Pull from server failed', error: e);
      _syncController.add(SyncStatus.error);
    }
  }

  Future<void> _pullCollection(
    Databases databases,
    String databaseId,
    String collectionId,
    String userId,
  ) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [Query.equal('user_id', userId)],
      );

      final db = await _dbHelper.database;
      final localTable = _getLocalTableName(collectionId);

      for (final doc in response.documents) {
        // Check if local version exists and is newer
        final localData = await db.query(
          localTable,
          where: 'id = ?',
          whereArgs: [doc.$id],
        );

        if (localData.isEmpty) {
          // Insert new record
          await db.insert(localTable, _mapDocumentToLocal(doc.data));
        } else {
          final localUpdatedAt = localData.first['updated_at'] as int?;
          final serverUpdatedAt = DateTime.parse(doc.data['\$updatedAt'] as String)
              .millisecondsSinceEpoch;

          if (localUpdatedAt == null || serverUpdatedAt > localUpdatedAt) {
            // Server version is newer
            await db.update(
              localTable,
              _mapDocumentToLocal(doc.data),
              where: 'id = ?',
              whereArgs: [doc.$id],
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to pull $collectionId', error: e);
    }
  }

  String _getLocalTableName(String collectionId) {
    final mapping = {
      'user_progress': 'user_progress',
      'lesson_progress': 'lesson_progress',
      'user_achievements': 'user_achievements',
      'follows': 'follows',
      'notifications': 'notifications',
      'messages': 'messages',
      'support_tickets': 'support_tickets',
      'user_settings': 'settings',
    };
    return mapping[collectionId] ?? collectionId;
  }

  Map<String, dynamic> _mapDocumentToLocal(Map<String, dynamic> data) {
    // Remove Appwrite specific fields and convert to local format
    final result = Map<String, dynamic>.from(data);
    result.remove('\$id');
    result.remove('\$collectionId');
    result.remove('\$databaseId');
    result.remove('\$createdAt');
    result.remove('\$updatedAt');
    result.remove('\$permissions');
    
    // Convert datetime strings to milliseconds
    result.forEach((key, value) {
      if (value is String && _isIsoDateString(value)) {
        result[key] = DateTime.parse(value).millisecondsSinceEpoch;
      }
    });
    
    return result;
  }

  bool _isIsoDateString(String value) {
    try {
      DateTime.parse(value);
      return value.contains('T') || value.contains('-');
    } catch (_) {
      return false;
    }
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    final pending = await _syncQueueDao.getPendingItems(limit: 1000);
    return pending.length;
  }

  /// Clear all sync queue (use with caution)
  Future<void> clearSyncQueue() async {
    await _syncQueueDao.deleteCompleted();
    AppLogger.info('Sync queue cleared');
  }

  void dispose() {
    stopAutoSync();
    _syncController.close();
  }
}

/// Sync status
enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
  offline,
}

/// Sync result
class SyncResult {
  final bool success;
  final String message;
  final int itemsSynced;
  final int itemsFailed;

  SyncResult({
    required this.success,
    required this.message,
    required this.itemsSynced,
    required this.itemsFailed,
  });
}
