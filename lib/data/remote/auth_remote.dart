import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import '../models/user.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class AuthRemote {
  final AppwriteClient _appwriteClient;

  AuthRemote(this._appwriteClient);

  Account get _account => _appwriteClient.account;
  Databases get _databases => _appwriteClient.databases;

  Future<models.User> createEmailSession({
    required String email,
    required String password,
  }) async {
    try {
      // Check if there's already an active session
      try {
        final existingUser = await _account.get();
        // Session exists, return the existing user
        return existingUser;
      } catch (_) {
        // No active session, proceed to create one
      }
      
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return await _account.get();
    } on AppwriteException catch (e) {
      AppLogger.logError('AuthRemote', 'createEmailSession', e);
      throw _mapAppwriteException(e);
    }
  }

  Future<models.User> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Check if there's already an active session and delete it
      try {
        await _account.get();
        await _account.deleteSession(sessionId: 'current');
      } catch (_) {
        // No active session, proceed
      }
      
      await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return await _account.get();
    } on AppwriteException catch (e) {
      AppLogger.logError('AuthRemote', 'createAccount', e);
      throw _mapAppwriteException(e);
    }
  }

  Future<models.User> signInWithGoogle() async {
    try {
      // Check if there's already an active session
      try {
        final existingUser = await _account.get();
        // Session exists, return the existing user
        return existingUser;
      } catch (_) {
        // No active session, proceed with OAuth
      }
      
      // Use Appwrite's built-in OAuth2 flow
      // This opens a browser/webview for Google authentication
      // and handles the redirect back to the app
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        // For Android: make sure to configure the deep link in AndroidManifest.xml
        // For iOS: make sure to configure the URL scheme in Info.plist
        // Success and failure URLs should match your app's deep link scheme
        scopes: ['email', 'profile'],
      );

      // After successful OAuth, get the user
      return await _account.get();
    } on AppwriteException catch (e) {
      AppLogger.logError('AuthRemote', 'signInWithGoogle', e);
      throw _mapAppwriteException(e);
    } catch (e) {
      AppLogger.logError('AuthRemote', 'signInWithGoogle', e);
      throw AuthException(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      AppLogger.logError('AuthRemote', 'signOut', e);
      throw _mapAppwriteException(e);
    }
  }

  Future<models.User?> getCurrentUser() async {
    try {
      return await _account.get();
    } on AppwriteException {
      return null;
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.usersCollection,
        documentId: userId,
      );
      return UserModel.fromMap({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      AppLogger.logError('AuthRemote', 'getUserProfile', e);
      throw _mapAppwriteException(e);
    }
  }

  Future<UserModel> createUserProfile(UserModel user) async {
    try {
      // Remove 'id' from data - Appwrite uses documentId separately
      final data = user.toMap()..remove('id');
      final doc = await _databases.createDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.usersCollection,
        documentId: user.id,
        data: data,
      );
      return UserModel.fromMap({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      AppLogger.logError('AuthRemote', 'createUserProfile', e);
      throw _mapAppwriteException(e);
    }
  }

  Future<UserModel> updateUserProfile(UserModel user) async {
    try {
      // Remove 'id' from data - Appwrite uses documentId separately
      final data = user.toMap()..remove('id');
      final doc = await _databases.updateDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.usersCollection,
        documentId: user.id,
        data: data,
      );
      return UserModel.fromMap({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      AppLogger.logError('AuthRemote', 'updateUserProfile', e);
      throw _mapAppwriteException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _account.createRecovery(
        email: email,
        url: 'https://tenzin.app/reset-password',
      );
    } on AppwriteException catch (e) {
      AppLogger.logError('AuthRemote', 'sendPasswordResetEmail', e);
      throw _mapAppwriteException(e);
    }
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _account.updatePassword(
        password: newPassword,
        oldPassword: oldPassword,
      );
    } on AppwriteException catch (e) {
      AppLogger.logError('AuthRemote', 'updatePassword', e);
      throw _mapAppwriteException(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      // Delete user data first
      final user = await getCurrentUser();
      if (user != null) {
        await _databases.deleteDocument(
          databaseId: AppwriteClient.databaseId,
          collectionId: AppwriteClient.usersCollection,
          documentId: user.$id,
        );
      }
      // Note: Account deletion requires admin privileges in Appwrite
      // This should be handled by a server function
    } on AppwriteException catch (e) {
      AppLogger.logError('AuthRemote', 'deleteAccount', e);
      throw _mapAppwriteException(e);
    }
  }

  /// Search users by display name or username
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.usersCollection,
        queries: [
          Query.search('display_name', query),
          Query.limit(50),
        ],
      );

      return response.documents
          .map((doc) => UserModel.fromMap({...doc.data, 'id': doc.$id}))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('AuthRemote', 'searchUsers', e);
      // If search fails (e.g., no fulltext index), try contains query
      try {
        final response = await _databases.listDocuments(
          databaseId: AppwriteClient.databaseId,
          collectionId: AppwriteClient.usersCollection,
          queries: [
            Query.contains('display_name', query),
            Query.limit(50),
          ],
        );
        return response.documents
            .map((doc) => UserModel.fromMap({...doc.data, 'id': doc.$id}))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Exception _mapAppwriteException(AppwriteException e) {
    // Handle specific error types first
    if (e.type == 'user_session_already_exists') {
      return const AuthException('Session already exists. Please try again.');
    }
    if (e.type == 'user_already_exists') {
      return const AuthException('User already exists');
    }
    if (e.type == 'user_invalid_credentials') {
      return const AuthException('Invalid email or password');
    }
    
    switch (e.code) {
      case 401:
        return const AuthException('Invalid credentials');
      case 404:
        return const AuthException('User not found');
      case 409:
        return const AuthException('User already exists');
      case 429:
        return const AuthException('Too many requests. Please try again later.');
      default:
        return ServerException(e.message ?? 'An error occurred');
    }
  }
}
