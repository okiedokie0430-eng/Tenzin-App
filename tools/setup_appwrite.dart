// Appwrite Database Setup Script for Tenzin App
// Run with: dart run tools/setup_appwrite.dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/enums.dart';

// Configuration
const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
const String projectId = '69536e3f003c0ac930bd';
const String apiKey = 'standard_8f459dac146c7636ee92a3610600a5c695ad1a722e3e6476a935391b26ece18b0ce20cbf023116e33bca8a27ebb5ad1829f76c9567203a30206024ece07fb41d91b420a329e001d7392149c281d57574449fa8f633eca6216d7644c97113372dfa00d2d0133af154e73e0962c6e9c910025fdbdac574a631bcf172e73b0ac539';
const String databaseId = 'collection';

late Client client;
late Databases databases;
late Storage storage;

void main() async {
  print('🚀 Starting Appwrite Setup for Tenzin App...\n');

  // Initialize client
  client = Client()
    ..setEndpoint(endpoint)
    ..setProject(projectId)
    ..setKey(apiKey);

  databases = Databases(client);
  storage = Storage(client);

  try {
    // Step 1: Create or verify database
    await setupDatabase();

    // Step 2: Create all collections
    await setupCollections();

    // Step 3: Create storage buckets
    await setupStorageBuckets();

    print('\n✅ Appwrite setup completed successfully!');
    print('📱 Your app is now ready to use with the configured backend.');
  } catch (e) {
    print('\n❌ Error during setup: $e');
    exit(1);
  }
}

Future<void> setupDatabase() async {
  print('📦 Setting up database...');
  try {
    await databases.get(databaseId: databaseId);
    print('   ✓ Database "$databaseId" already exists');
  } catch (e) {
    try {
      await databases.create(
        databaseId: databaseId,
        name: 'Tenzin Collection',
      );
      print('   ✓ Database "$databaseId" created');
    } catch (e) {
      print('   ⚠ Database error: $e');
    }
  }
}

Future<void> setupCollections() async {
  print('\n📚 Setting up collections...\n');

  // 1. User Profiles
  await createCollection(
    id: 'user_profiles',
    name: 'User Profiles',
    attributes: [
      StringAttr('email', size: 320, required: true),
      StringAttr('display_name', size: 100, required: true),
      StringAttr('username', size: 50),
      StringAttr('bio', size: 500),
      StringAttr('avatar_url', size: 500),
      StringAttr('auth_providers', size: 500), // JSON array
      IntAttr('total_xp', defaultValue: 0),
      IntAttr('weekly_xp', defaultValue: 0),
      IntAttr('current_streak_days', defaultValue: 0),
      IntAttr('longest_streak_days', defaultValue: 0),
      IntAttr('follower_count', defaultValue: 0),
      IntAttr('following_count', defaultValue: 0),
      IntAttr('lessons_completed', defaultValue: 0),
      IntAttr('last_lesson_date'),
      IntAttr('last_sync_at'),
      StringAttr('sync_status', size: 20, defaultValue: 'pending'),
      IntAttr('last_modified_at', required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_email', ['email']),
      IndexDef('idx_username', ['username']),
      IndexDef('idx_weekly_xp', ['weekly_xp'], type: 'key'),
    ],
  );

  // 2. User Settings
  await createCollection(
    id: 'user_settings',
    name: 'User Settings',
    attributes: [
      StringAttr('user_id', size: 36, required: true),
      BoolAttr('notification_new_follower', defaultValue: true),
      BoolAttr('notification_leaderboard_rank', defaultValue: true),
      BoolAttr('notification_messages', defaultValue: true),
      BoolAttr('notification_achievements', defaultValue: true),
      BoolAttr('storage_permission_granted', defaultValue: false),
      BoolAttr('sound_enabled', defaultValue: true),
      BoolAttr('music_enabled', defaultValue: true),
      BoolAttr('daily_reminder_enabled', defaultValue: true),
      StringAttr('daily_reminder_time', size: 10, defaultValue: '09:00'),
      StringAttr('theme', size: 20, defaultValue: 'system'),
      StringAttr('sync_status', size: 20, defaultValue: 'pending'),
      IntAttr('last_modified_at', required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_user_id', ['user_id'], type: 'unique'),
    ],
  );

  // 3. User Progress
  await createCollection(
    id: 'user_progress',
    name: 'User Progress',
    attributes: [
      StringAttr('user_id', size: 36, required: true),
      StringAttr('lesson_id', size: 36, required: true),
      StringAttr('status', size: 20, defaultValue: 'notStarted'),
      IntAttr('correct_answers', defaultValue: 0),
      IntAttr('total_questions', defaultValue: 0),
      IntAttr('xp_earned', defaultValue: 0),
      IntAttr('hearts_remaining', defaultValue: 5),
      IntAttr('completed_at'),
      IntAttr('attempts', defaultValue: 0),
      IntAttr('time_spent_seconds', defaultValue: 0),
      StringAttr('sync_status', size: 20, defaultValue: 'pending'),
      IntAttr('last_modified_at', required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_user_lesson', ['user_id', 'lesson_id'], type: 'unique'),
      IndexDef('idx_user_id', ['user_id']),
    ],
  );

  // 4. Heart State
  await createCollection(
    id: 'heart_state',
    name: 'Heart State',
    attributes: [
      StringAttr('user_id', size: 36, required: true),
      IntAttr('current_hearts', defaultValue: 5),
      IntAttr('last_heart_loss_at'),
      IntAttr('last_regeneration_at'),
      StringAttr('sync_status', size: 20, defaultValue: 'pending'),
      IntAttr('last_modified_at', required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_user_id', ['user_id'], type: 'unique'),
    ],
  );

  // 5. Follows
  await createCollection(
    id: 'follows',
    name: 'Follows',
    attributes: [
      StringAttr('follower_id', size: 36, required: true),
      StringAttr('following_id', size: 36, required: true),
      IntAttr('created_at', required: true),
      StringAttr('sync_status', size: 20, defaultValue: 'pending'),
      IntAttr('last_modified_at', required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_follower', ['follower_id']),
      IndexDef('idx_following', ['following_id']),
      IndexDef('idx_follow_pair', ['follower_id', 'following_id'], type: 'unique'),
    ],
  );

  // 6. Messages
  await createCollection(
    id: 'messages',
    name: 'Messages',
    attributes: [
      StringAttr('sender_id', size: 36, required: true),
      StringAttr('receiver_id', size: 36, required: true),
      StringAttr('message', size: 1000, required: true),
      IntAttr('created_at', required: true),
      IntAttr('read_at'),
      StringAttr('sync_status', size: 20, defaultValue: 'pending'),
      StringAttr('appwrite_message_id', size: 36),
      IntAttr('last_modified_at', required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_sender', ['sender_id']),
      IndexDef('idx_receiver', ['receiver_id']),
      IndexDef('idx_conversation', ['sender_id', 'receiver_id']),
    ],
  );

  // 7. Achievements (master list)
  await createCollection(
    id: 'achievements',
    name: 'Achievements',
    attributes: [
      StringAttr('name', size: 100, required: true),
      StringAttr('description', size: 500, required: true),
      StringAttr('icon_asset', size: 200),
      StringAttr('type', size: 50, defaultValue: 'lessons'),
      StringAttr('unlock_criteria', size: 1000, required: true), // JSON
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_type', ['type']),
    ],
  );

  // 8. User Achievements (unlocked by users)
  await createCollection(
    id: 'user_achievements',
    name: 'User Achievements',
    attributes: [
      StringAttr('user_id', size: 36, required: true),
      StringAttr('achievement_id', size: 36, required: true),
      IntAttr('unlocked_at', required: true),
      StringAttr('sync_status', size: 20, defaultValue: 'pending'),
      IntAttr('last_modified_at', required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_user_id', ['user_id']),
      IndexDef('idx_user_achievement', ['user_id', 'achievement_id'], type: 'unique'),
    ],
  );

  // 9. Leaderboard
  await createCollection(
    id: 'leaderboard',
    name: 'Leaderboard',
    attributes: [
      StringAttr('user_id', size: 36, required: true),
      IntAttr('week_start_date', required: true),
      IntAttr('weekly_xp', defaultValue: 0),
      IntAttr('rank', defaultValue: 0),
      StringAttr('sync_status', size: 20, defaultValue: 'pending'),
      IntAttr('last_modified_at', required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_user_week', ['user_id', 'week_start_date'], type: 'unique'),
      IndexDef('idx_week_xp', ['week_start_date', 'weekly_xp']),
    ],
  );

  // 10. Notifications
  await createCollection(
    id: 'notifications',
    name: 'Notifications',
    attributes: [
      StringAttr('user_id', size: 36, required: true),
      StringAttr('type', size: 50, required: true),
      StringAttr('title', size: 200, required: true),
      StringAttr('message', size: 500, required: true),
      StringAttr('related_user_id', size: 36),
      IntAttr('created_at', required: true),
      IntAttr('read_at'),
      StringAttr('sync_status', size: 20, defaultValue: 'pending'),
      IntAttr('last_modified_at', required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_user_id', ['user_id']),
      IndexDef('idx_user_created', ['user_id', 'created_at']),
    ],
  );

  // 11. Support Messages
  await createCollection(
    id: 'support_messages',
    name: 'Support Messages',
    attributes: [
      StringAttr('user_id', size: 36, required: true),
      StringAttr('message', size: 2000, required: true),
      IntAttr('created_at', required: true),
      StringAttr('admin_response', size: 2000),
      IntAttr('responded_at'),
      StringAttr('status', size: 20, defaultValue: 'open'),
      StringAttr('sync_status', size: 20, defaultValue: 'pending'),
      StringAttr('appwrite_message_id', size: 36),
    ],
    indexes: [
      IndexDef('idx_user_id', ['user_id']),
      IndexDef('idx_status', ['status']),
    ],
  );

  // 12. Lessons
  await createCollection(
    id: 'lessons',
    name: 'Lessons',
    attributes: [
      StringAttr('title', size: 200, required: true),
      StringAttr('description', size: 1000),
      StringAttr('type', size: 50, defaultValue: 'vocabulary'),
      IntAttr('sequence_order', required: true),
      StringAttr('tree_path', size: 200, required: true),
      IntAttr('word_count', required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_sequence', ['sequence_order']),
      IndexDef('idx_tree_path', ['tree_path']),
      IndexDef('idx_type', ['type']),
    ],
  );

  // 13. Lesson Words
  await createCollection(
    id: 'lesson_words',
    name: 'Lesson Words',
    attributes: [
      StringAttr('lesson_id', size: 36, required: true),
      StringAttr('parent_word_id', size: 36),
      IntAttr('word_order', required: true),
      StringAttr('tibetan_script', size: 500, required: true),
      StringAttr('phonetic', size: 500, required: true),
      StringAttr('mongolian_translation', size: 500, required: true),
      IntAttr('version', defaultValue: 1),
    ],
    indexes: [
      IndexDef('idx_lesson_id', ['lesson_id']),
      IndexDef('idx_lesson_order', ['lesson_id', 'word_order']),
    ],
  );
}

Future<void> setupStorageBuckets() async {
  print('\n🗄️ Setting up storage buckets...\n');

  // Profile Images Bucket
  await createBucket(
    id: 'profile_images',
    name: 'Profile Images',
    maxFileSize: 5 * 1024 * 1024, // 5MB
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
  );

  // Lesson Images Bucket
  await createBucket(
    id: 'lesson_images',
    name: 'Lesson Images',
    maxFileSize: 10 * 1024 * 1024, // 10MB
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    permissions: [
      Permission.read(Role.any()),
    ],
  );

  // Audio Files Bucket
  await createBucket(
    id: 'audio_files',
    name: 'Audio Files',
    maxFileSize: 20 * 1024 * 1024, // 20MB
    allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a'],
    permissions: [
      Permission.read(Role.any()),
    ],
  );
}

// Helper classes for attribute definitions
class StringAttr {
  final String key;
  final int size;
  final bool required;
  final String? defaultValue;
  final bool isArray;

  StringAttr(this.key, {this.size = 255, this.required = false, this.defaultValue, this.isArray = false});
}

class IntAttr {
  final String key;
  final bool required;
  final int? defaultValue;

  IntAttr(this.key, {this.required = false, this.defaultValue});
}

class BoolAttr {
  final String key;
  final bool required;
  final bool? defaultValue;

  BoolAttr(this.key, {this.required = false, this.defaultValue});
}

class IndexDef {
  final String key;
  final List<String> attributes;
  final String type;

  IndexDef(this.key, this.attributes, {this.type = 'key'});
}

Future<void> createCollection({
  required String id,
  required String name,
  required List<dynamic> attributes,
  List<IndexDef> indexes = const [],
}) async {
  print('📁 Collection: $name ($id)');

  // Check if collection exists
  bool exists = false;
  try {
    await databases.getCollection(databaseId: databaseId, collectionId: id);
    exists = true;
    print('   ✓ Collection already exists');
  } catch (e) {
    // Collection doesn't exist, create it
  }

  if (!exists) {
    try {
      await databases.createCollection(
        databaseId: databaseId,
        collectionId: id,
        name: name,
        permissions: [
          Permission.read(Role.users()),
          Permission.create(Role.users()),
          Permission.update(Role.users()),
          Permission.delete(Role.users()),
        ],
        documentSecurity: true,
      );
      print('   ✓ Collection created');
    } catch (e) {
      print('   ⚠ Error creating collection: $e');
      return;
    }
  }

  // Create attributes
  for (var attr in attributes) {
    await createAttribute(id, attr);
  }

  // Create indexes
  for (var index in indexes) {
    await createIndex(id, index);
  }
}

Future<void> createAttribute(String collectionId, dynamic attr) async {
  try {
    if (attr is StringAttr) {
      await databases.createStringAttribute(
        databaseId: databaseId,
        collectionId: collectionId,
        key: attr.key,
        size: attr.size,
        xrequired: attr.required,
        xdefault: attr.defaultValue,
        array: attr.isArray,
      );
      print('   ✓ Attribute: ${attr.key} (string)');
    } else if (attr is IntAttr) {
      await databases.createIntegerAttribute(
        databaseId: databaseId,
        collectionId: collectionId,
        key: attr.key,
        xrequired: attr.required,
        xdefault: attr.defaultValue,
      );
      print('   ✓ Attribute: ${attr.key} (integer)');
    } else if (attr is BoolAttr) {
      await databases.createBooleanAttribute(
        databaseId: databaseId,
        collectionId: collectionId,
        key: attr.key,
        xrequired: attr.required,
        xdefault: attr.defaultValue,
      );
      print('   ✓ Attribute: ${attr.key} (boolean)');
    }
  } catch (e) {
    if (e.toString().contains('already exists')) {
      print('   · Attribute: ${attr is StringAttr ? attr.key : attr is IntAttr ? attr.key : (attr as BoolAttr).key} (exists)');
    } else {
      print('   ⚠ Attribute error: $e');
    }
  }
}

Future<void> createIndex(String collectionId, IndexDef index) async {
  try {
    await databases.createIndex(
      databaseId: databaseId,
      collectionId: collectionId,
      key: index.key,
      type: index.type == 'unique' ? IndexType.unique : IndexType.key,
      attributes: index.attributes,
    );
    print('   ✓ Index: ${index.key}');
  } catch (e) {
    if (e.toString().contains('already exists')) {
      print('   · Index: ${index.key} (exists)');
    } else {
      print('   ⚠ Index error: $e');
    }
  }
}

Future<void> createBucket({
  required String id,
  required String name,
  required int maxFileSize,
  required List<String> allowedExtensions,
  required List<String> permissions,
}) async {
  print('🗂️ Bucket: $name ($id)');

  try {
    await storage.getBucket(bucketId: id);
    print('   ✓ Bucket already exists');
  } catch (e) {
    try {
      await storage.createBucket(
        bucketId: id,
        name: name,
        permissions: permissions,
        fileSecurity: true,
        maximumFileSize: maxFileSize,
        allowedFileExtensions: allowedExtensions,
        compression: Compression.gzip,
      );
      print('   ✓ Bucket created');
    } catch (e) {
      print('   ⚠ Bucket error: $e');
    }
  }
}
