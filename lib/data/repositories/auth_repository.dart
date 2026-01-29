import '../models/user.dart';
import '../local/daos/user_dao.dart';
import '../remote/auth_remote.dart';
import '../../core/platform/network_info.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

class AuthRepository {
  final AuthRemote _authRemote;
  final UserDao _userDao;
  final NetworkInfo _networkInfo;

  AuthRepository(this._authRemote, this._userDao, this._networkInfo);

  Future<({UserModel? user, Failure? failure})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        return (user: null, failure: Failure.network());
      }

      final appwriteUser = await _authRemote.createEmailSession(
        email: email,
        password: password,
      );

      var userProfile = await _authRemote.getUserProfile(appwriteUser.$id);
      
      if (userProfile == null) {
        final now = DateTime.now();
        userProfile = UserModel(
          id: appwriteUser.$id,
          email: appwriteUser.email,
          displayName: appwriteUser.name,
          lastModifiedAt: now.millisecondsSinceEpoch,
          syncStatus: SyncStatus.synced,
        );
        await _authRemote.createUserProfile(userProfile);
      }

      await _userDao.insert(userProfile);
      
      return (user: userProfile, failure: null);
    } on AuthException catch (e) {
      AppLogger.logError('AuthRepository', 'signInWithEmail', e);
      return (user: null, failure: Failure.auth(e.message));
    } catch (e) {
      AppLogger.logError('AuthRepository', 'signInWithEmail', e);
      return (user: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({UserModel? user, Failure? failure})> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        return (user: null, failure: Failure.network());
      }

      final appwriteUser = await _authRemote.createAccount(
        email: email,
        password: password,
        name: name,
      );

      final now = DateTime.now();
      final userProfile = UserModel(
        id: appwriteUser.$id,
        email: appwriteUser.email,
        displayName: name,
        lastModifiedAt: now.millisecondsSinceEpoch,
        syncStatus: SyncStatus.synced,
      );

      await _authRemote.createUserProfile(userProfile);
      await _userDao.insert(userProfile);

      return (user: userProfile, failure: null);
    } on AuthException catch (e) {
      AppLogger.logError('AuthRepository', 'signUpWithEmail', e);
      return (user: null, failure: Failure.auth(e.message));
    } catch (e) {
      AppLogger.logError('AuthRepository', 'signUpWithEmail', e);
      return (user: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({UserModel? user, Failure? failure})> signInWithGoogle() async {
    try {
      if (!await _networkInfo.isConnected) {
        return (user: null, failure: Failure.network());
      }

      final appwriteUser = await _authRemote.signInWithGoogle();

      var userProfile = await _authRemote.getUserProfile(appwriteUser.$id);
      
      if (userProfile == null) {
        final now = DateTime.now();
        userProfile = UserModel(
          id: appwriteUser.$id,
          email: appwriteUser.email,
          displayName: appwriteUser.name,
          lastModifiedAt: now.millisecondsSinceEpoch,
          syncStatus: SyncStatus.synced,
        );
        await _authRemote.createUserProfile(userProfile);
      }

      await _userDao.insert(userProfile);

      return (user: userProfile, failure: null);
    } on AuthException catch (e) {
      AppLogger.logError('AuthRepository', 'signInWithGoogle', e);
      return (user: null, failure: Failure.auth(e.message));
    } catch (e) {
      AppLogger.logError('AuthRepository', 'signInWithGoogle', e);
      return (user: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<Failure?> signOut() async {
    try {
      await _authRemote.signOut();
      return null;
    } on AuthException catch (e) {
      AppLogger.logError('AuthRepository', 'signOut', e);
      return Failure.auth(e.message);
    } catch (e) {
      AppLogger.logError('AuthRepository', 'signOut', e);
      return Failure.unknown(e.toString());
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final appwriteUser = await _authRemote.getCurrentUser();
      if (appwriteUser == null) return null;

      // Try local first
      var user = await _userDao.getById(appwriteUser.$id);
      
      if (user == null && await _networkInfo.isConnected) {
        user = await _authRemote.getUserProfile(appwriteUser.$id);
        if (user != null) {
          await _userDao.insert(user);
        }
      }

      return user;
    } catch (e) {
      AppLogger.logError('AuthRepository', 'getCurrentUser', e);
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final user = await _authRemote.getCurrentUser();
    return user != null;
  }

  Future<({UserModel? user, Failure? failure})> updateProfile(
    UserModel user,
  ) async {
    try {
      // Update local first
      final localUser = user.copyWith(syncStatus: SyncStatus.pending);
      await _userDao.update(localUser);

      if (await _networkInfo.isConnected) {
        final remoteUser = await _authRemote.updateUserProfile(user);
        final syncedUser = remoteUser.copyWith(syncStatus: SyncStatus.synced);
        await _userDao.update(syncedUser);
        return (user: syncedUser, failure: null);
      }

      return (user: localUser, failure: null);
    } catch (e) {
      AppLogger.logError('AuthRepository', 'updateProfile', e);
      return (user: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<Failure?> sendPasswordResetEmail(String email) async {
    try {
      if (!await _networkInfo.isConnected) {
        return Failure.network();
      }

      await _authRemote.sendPasswordResetEmail(email);
      return null;
    } on AuthException catch (e) {
      return Failure.auth(e.message);
    } catch (e) {
      return Failure.unknown(e.toString());
    }
  }

  Future<Failure?> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        return Failure.network();
      }

      await _authRemote.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return null;
    } on AuthException catch (e) {
      return Failure.auth(e.message);
    } catch (e) {
      return Failure.unknown(e.toString());
    }
  }

  Future<Failure?> deleteAccount() async {
    try {
      if (!await _networkInfo.isConnected) {
        return Failure.network();
      }

      final user = await getCurrentUser();
      if (user != null) {
        await _userDao.delete(user.id);
      }

      await _authRemote.deleteAccount();
      return null;
    } catch (e) {
      AppLogger.logError('AuthRepository', 'deleteAccount', e);
      return Failure.unknown(e.toString());
    }
  }

  /// Search users by name or username
  Future<({List<UserModel> users, Failure? failure})> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) {
        return (users: <UserModel>[], failure: null);
      }

      // Try remote search first if connected
      if (await _networkInfo.isConnected) {
        final users = await _authRemote.searchUsers(query);
        // Cache users locally
        for (final user in users) {
          await _userDao.insert(user);
        }
        return (users: users, failure: null);
      }

      // Fall back to local search
      final localUsers = await _userDao.searchByName(query);
      return (users: localUsers, failure: null);
    } catch (e) {
      AppLogger.logError('AuthRepository', 'searchUsers', e);
      // Try local search on error
      try {
        final localUsers = await _userDao.searchByName(query);
        return (users: localUsers, failure: null);
      } catch (_) {
        return (users: <UserModel>[], failure: Failure.unknown(e.toString()));
      }
    }
  }

  /// Get another user's profile by ID
  Future<({UserModel? user, Failure? failure})> getUserById(String userId) async {
    try {
      // Try local first
      var user = await _userDao.getById(userId);
      
      if (user != null) {
        // If we have a local copy, try to refresh from remote
        if (await _networkInfo.isConnected) {
          try {
            final remoteUser = await _authRemote.getUserProfile(userId);
            if (remoteUser != null) {
              await _userDao.insert(remoteUser);
              return (user: remoteUser, failure: null);
            }
          } catch (_) {
            // Use local copy on error
          }
        }
        return (user: user, failure: null);
      }

      // Not in local, fetch from remote
      if (await _networkInfo.isConnected) {
        user = await _authRemote.getUserProfile(userId);
        if (user != null) {
          await _userDao.insert(user);
          return (user: user, failure: null);
        }
      }

      return (user: null, failure: Failure.unknown('User not found'));
    } catch (e) {
      AppLogger.logError('AuthRepository', 'getUserById', e);
      return (user: null, failure: Failure.unknown(e.toString()));
    }
  }
}
