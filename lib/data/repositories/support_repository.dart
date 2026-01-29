import '../models/support_message.dart';
import '../models/user.dart';
import '../local/daos/support_dao.dart';
import '../remote/support_remote.dart';
import '../../core/platform/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

class SupportRepository {
  final SupportRemote _supportRemote;
  final SupportDao _supportDao;
  final NetworkInfo _networkInfo;

  SupportRepository(this._supportRemote, this._supportDao, this._networkInfo);

  Future<({List<SupportMessageModel> messages, Failure? failure})> getMessages(
    String userId,
  ) async {
    try {
      if (await _networkInfo.isConnected) {
        final remoteMessages = await _supportRemote.getUserMessages(userId);
        for (final message in remoteMessages) {
          await _supportDao.insert(message.copyWith(syncStatus: SyncStatus.synced));
        }
      }
      
      final localMessages = await _supportDao.getByUser(userId);
      return (messages: localMessages, failure: null);
    } catch (e) {
      AppLogger.logError('SupportRepository', 'getMessages', e);
      final localMessages = await _supportDao.getByUser(userId);
      return (
        messages: localMessages,
        failure: Failure.unknown(e.toString()),
      );
    }
  }

  Future<({SupportMessageModel? message, Failure? failure})> sendMessage({
    required String userId,
    required String messageText,
  }) async {
    try {
      final now = DateTime.now();
      final message = SupportMessageModel(
        id: '${userId}_${now.millisecondsSinceEpoch}',
        odUserId: userId,
        message: messageText,
        createdAt: now,
        syncStatus: SyncStatus.pending,
      );

      await _supportDao.insert(message);

      if (await _networkInfo.isConnected) {
        final remoteMessage = await _supportRemote.sendMessage(message);
        final syncedMessage = remoteMessage.copyWith(syncStatus: SyncStatus.synced);
        await _supportDao.insert(syncedMessage);
        return (message: syncedMessage, failure: null);
      }

      return (message: message, failure: null);
    } catch (e) {
      AppLogger.logError('SupportRepository', 'sendMessage', e);
      return (message: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<int> getUnrespondedCount(String userId) async {
    try {
      final messages = await _supportDao.getByUser(userId);
      return messages.where((m) => m.status == SupportMessageStatus.open).length;
    } catch (e) {
      AppLogger.logError('SupportRepository', 'getUnrespondedCount', e);
      return 0;
    }
  }

  Future<void> syncMessages(String userId, DateTime lastSyncTime) async {
    try {
      if (!await _networkInfo.isConnected) return;

      final updatedMessages = await _supportRemote.getMessagesUpdatedAfter(
        userId,
        lastSyncTime,
      );

      for (final message in updatedMessages) {
        await _supportDao.insert(message.copyWith(syncStatus: SyncStatus.synced));
      }
    } catch (e) {
      AppLogger.logError('SupportRepository', 'syncMessages', e);
    }
  }

  Future<void> syncPendingMessages() async {
    try {
      if (!await _networkInfo.isConnected) return;

      final pendingMessages = await _supportDao.getPendingSync();
      
      for (final message in pendingMessages) {
        try {
          final remoteMessage = await _supportRemote.sendMessage(message);
          await _supportDao.markAsSynced(message.id, remoteMessage.appwriteMessageId ?? '');
        } catch (e) {
          AppLogger.logError('SupportRepository', 'syncPendingMessages', e);
        }
      }
    } catch (e) {
      AppLogger.logError('SupportRepository', 'syncPendingMessages', e);
    }
  }
}
