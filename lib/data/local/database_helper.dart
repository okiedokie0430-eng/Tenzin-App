import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    AppLogger.logDatabase('Initializing', path);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.logDatabase('Creating tables', 'version $version');

    // USER PROFILE
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        display_name TEXT NOT NULL,
        username TEXT,
        bio TEXT,
        avatar_url TEXT,
        auth_providers TEXT DEFAULT '["email"]',
        total_xp INTEGER DEFAULT 0,
        weekly_xp INTEGER DEFAULT 0,
        current_streak_days INTEGER DEFAULT 0,
        longest_streak_days INTEGER DEFAULT 0,
        follower_count INTEGER DEFAULT 0,
        following_count INTEGER DEFAULT 0,
        lessons_completed INTEGER DEFAULT 0,
        last_lesson_date INTEGER,
        last_sync_at INTEGER,
        sync_status TEXT DEFAULT 'pending',
        last_modified_at INTEGER NOT NULL,
        version INTEGER DEFAULT 1
      )
    ''');

    // LESSONS
    await db.execute('''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT 'Хичээл',
        description TEXT,
        type TEXT NOT NULL DEFAULT 'vocabulary',
        sequence_order INTEGER NOT NULL UNIQUE,
        tree_path TEXT NOT NULL,
        word_count INTEGER NOT NULL,
        version INTEGER DEFAULT 1
      )
    ''');

    // LESSON WORDS
    await db.execute('''
      CREATE TABLE lesson_words (
        id TEXT PRIMARY KEY,
        lesson_id TEXT NOT NULL,
        parent_word_id TEXT,
        word_order INTEGER NOT NULL,
        tibetan_script TEXT NOT NULL,
        phonetic TEXT NOT NULL,
        mongolian_translation TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        FOREIGN KEY (lesson_id) REFERENCES lessons(id)
      )
    ''');

    // USER PROGRESS
    await db.execute('''
      CREATE TABLE user_progress (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        lesson_id TEXT NOT NULL,
        status TEXT DEFAULT 'notStarted',
        correct_answers INTEGER DEFAULT 0,
        total_questions INTEGER DEFAULT 0,
        xp_earned INTEGER DEFAULT 0,
        hearts_remaining INTEGER DEFAULT 5,
        completed_at INTEGER,
        attempts INTEGER DEFAULT 0,
        time_spent_seconds INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending',
        last_modified_at INTEGER NOT NULL,
        version INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES user_profile(id),
        FOREIGN KEY (lesson_id) REFERENCES lessons(id),
        UNIQUE(user_id, lesson_id)
      )
    ''');

    // HEART STATE
    await db.execute('''
      CREATE TABLE heart_state (
        user_id TEXT PRIMARY KEY,
        current_hearts INTEGER DEFAULT 5,
        last_heart_loss_at INTEGER,
        last_regeneration_at INTEGER,
        sync_status TEXT DEFAULT 'pending',
        last_modified_at INTEGER NOT NULL,
        version INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    // ACHIEVEMENTS
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_asset TEXT,
        type TEXT DEFAULT 'lesson',
        unlock_criteria TEXT NOT NULL,
        version INTEGER DEFAULT 1
      )
    ''');

    // USER ACHIEVEMENTS
    await db.execute('''
      CREATE TABLE user_achievements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        unlocked_at INTEGER NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        last_modified_at INTEGER NOT NULL,
        version INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES user_profile(id),
        FOREIGN KEY (achievement_id) REFERENCES achievements(id),
        UNIQUE(user_id, achievement_id)
      )
    ''');

    // FOLLOWS
    await db.execute('''
      CREATE TABLE follows (
        id TEXT PRIMARY KEY,
        follower_id TEXT NOT NULL,
        following_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        last_modified_at INTEGER NOT NULL,
        version INTEGER DEFAULT 1,
        FOREIGN KEY (follower_id) REFERENCES user_profile(id),
        FOREIGN KEY (following_id) REFERENCES user_profile(id),
        UNIQUE(follower_id, following_id)
      )
    ''');

    // MESSAGES
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        read_at INTEGER,
        sync_status TEXT DEFAULT 'pending',
        appwrite_message_id TEXT,
        last_modified_at INTEGER NOT NULL,
        version INTEGER DEFAULT 1,
        FOREIGN KEY (sender_id) REFERENCES user_profile(id),
        FOREIGN KEY (receiver_id) REFERENCES user_profile(id)
      )
    ''');

    // NOTIFICATIONS
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        related_user_id TEXT,
        created_at INTEGER NOT NULL,
        read_at INTEGER,
        sync_status TEXT DEFAULT 'pending',
        last_modified_at INTEGER NOT NULL,
        version INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    // LEADERBOARD
    await db.execute('''
      CREATE TABLE leaderboard (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        week_start_date INTEGER NOT NULL,
        weekly_xp INTEGER DEFAULT 0,
        rank INTEGER,
        sync_status TEXT DEFAULT 'pending',
        last_modified_at INTEGER NOT NULL,
        version INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES user_profile(id),
        UNIQUE(user_id, week_start_date)
      )
    ''');

    // SYNC QUEUE
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_attempt_at INTEGER,
        error_message TEXT
      )
    ''');

    // SUPPORT MESSAGES
    await db.execute('''
      CREATE TABLE support_messages (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        admin_response TEXT,
        responded_at INTEGER,
        status TEXT DEFAULT 'open',
        sync_status TEXT DEFAULT 'pending',
        appwrite_message_id TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    // APP METADATA
    await db.execute('''
      CREATE TABLE app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        last_modified_at INTEGER NOT NULL
      )
    ''');

    // USER SETTINGS
    await db.execute('''
      CREATE TABLE user_settings (
        user_id TEXT PRIMARY KEY,
        notification_new_follower INTEGER DEFAULT 1,
        notification_leaderboard_rank INTEGER DEFAULT 1,
        notification_messages INTEGER DEFAULT 1,
        notification_achievements INTEGER DEFAULT 1,
        storage_permission_granted INTEGER DEFAULT 0,
        sync_status TEXT DEFAULT 'pending',
        last_modified_at INTEGER NOT NULL,
        version INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    // Create indexes
    await _createIndexes(db);

    // TARNI COUNTERS (local storage for Tarni feature) - support multiple entries per user
    await db.execute('''
      CREATE TABLE tarni_counters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        magzushir INTEGER DEFAULT 0,
        janraisig INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_tarni_user ON tarni_counters(user_id)');

    // Insert default achievements
    await _insertDefaultAchievements(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Progress indexes
    await db.execute('CREATE INDEX idx_user_progress_user_lesson ON user_progress(user_id, lesson_id)');
    await db.execute('CREATE INDEX idx_user_progress_sync ON user_progress(sync_status, last_modified_at)');
    await db.execute('CREATE INDEX idx_sync_queue_status ON sync_queue(created_at, retry_count)');

    // Lesson indexes
    await db.execute('CREATE INDEX idx_lessons_sequence ON lessons(sequence_order)');
    await db.execute('CREATE INDEX idx_lesson_words_parent ON lesson_words(parent_word_id)');
    await db.execute('CREATE INDEX idx_lesson_words_lesson ON lesson_words(lesson_id)');

    // Social indexes
    await db.execute('CREATE INDEX idx_follows_follower ON follows(follower_id, created_at)');
    await db.execute('CREATE INDEX idx_follows_following ON follows(following_id, created_at)');
    await db.execute('CREATE INDEX idx_messages_receiver ON messages(receiver_id, created_at)');
    await db.execute('CREATE INDEX idx_messages_conversation ON messages(sender_id, receiver_id, created_at)');
    await db.execute('CREATE INDEX idx_notifications_user ON notifications(user_id, read_at, created_at)');
    await db.execute('CREATE INDEX idx_leaderboard_week ON leaderboard(week_start_date, rank)');
    await db.execute('CREATE INDEX idx_user_achievements_user ON user_achievements(user_id, unlocked_at)');
    await db.execute('CREATE INDEX idx_user_settings_user ON user_settings(user_id)');
  }

  Future<void> _insertDefaultAchievements(Database db) async {
    final achievements = [
      {
        'id': 'first_lesson',
        'name': 'Эхний алхам',
        'description': 'Эхний хичээлээ дуусга',
        'icon_asset': 'assets/icons/achievement_first_lesson.png',
        'unlock_criteria': '{"type": "lesson_count", "value": 1}',
      },
      {
        'id': '10_lessons',
        'name': 'Тэнцвэртэй',
        'description': '10 хичээл дуусга',
        'icon_asset': 'assets/icons/achievement_10_lessons.png',
        'unlock_criteria': '{"type": "lesson_count", "value": 10}',
      },
      {
        'id': '42_lessons',
        'name': 'Мастер',
        'description': 'Бүх 42 хичээлийг дуусга',
        'icon_asset': 'assets/icons/achievement_42_lessons.png',
        'unlock_criteria': '{"type": "lesson_count", "value": 42}',
      },
      {
        'id': '7_day_streak',
        'name': 'Долоо хоногийн streak',
        'description': '7 хоног дараалан суралц',
        'icon_asset': 'assets/icons/achievement_7_day_streak.png',
        'unlock_criteria': '{"type": "streak_days", "value": 7}',
      },
      {
        'id': '30_day_streak',
        'name': 'Сарын streak',
        'description': '30 хоног дараалан суралц',
        'icon_asset': 'assets/icons/achievement_30_day_streak.png',
        'unlock_criteria': '{"type": "streak_days", "value": 30}',
      },
      {
        'id': 'first_follower',
        'name': 'Анхны дагагч',
        'description': 'Эхний дагагчаа ол',
        'icon_asset': 'assets/icons/achievement_first_follower.png',
        'unlock_criteria': '{"type": "follower_count", "value": 1}',
      },
      {
        'id': '10_followers',
        'name': 'Алдартай',
        'description': '10 дагагчтай бол',
        'icon_asset': 'assets/icons/achievement_10_followers.png',
        'unlock_criteria': '{"type": "follower_count", "value": 10}',
      },
      {
        'id': 'leaderboard_top_10',
        'name': 'Шилдэг 10',
        'description': 'Лидерборд шилдэг 10-д орох',
        'icon_asset': 'assets/icons/achievement_top_10.png',
        'unlock_criteria': '{"type": "leaderboard_rank", "value": 10}',
      },
      {
        'id': 'leaderboard_top_1',
        'name': 'Тэргүүн',
        'description': 'Лидерборд 1-р байр эзлэх',
        'icon_asset': 'assets/icons/achievement_top_1.png',
        'unlock_criteria': '{"type": "leaderboard_rank", "value": 1}',
      },
    ];

    for (final achievement in achievements) {
      await db.insert('achievements', achievement);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.logDatabase('Upgrading', 'from $oldVersion to $newVersion');
    
    // Handle migrations based on version numbers
    if (oldVersion < 2) {
      // Migration to version 2: Add missing columns to user_profile
      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN username TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN bio TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE user_profile ADD COLUMN avatar_url TEXT');
      } catch (_) {}
    }

    if (oldVersion < 3) {
      // Migration to version 3: Recreate lessons table with new schema
      // Lessons are now LOCAL-ONLY and loaded from assets/data/lessons.json
      try {
        await db.execute('DROP TABLE IF EXISTS lesson_words');
        await db.execute('DROP TABLE IF EXISTS lessons');
        
        // Recreate lessons table with all columns
        await db.execute('''
          CREATE TABLE lessons (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL DEFAULT 'Хичээл',
            description TEXT,
            type TEXT NOT NULL DEFAULT 'vocabulary',
            sequence_order INTEGER NOT NULL UNIQUE,
            tree_path TEXT NOT NULL,
            word_count INTEGER NOT NULL,
            version INTEGER DEFAULT 1
          )
        ''');
        
        // Recreate lesson_words table
        await db.execute('''
          CREATE TABLE lesson_words (
            id TEXT PRIMARY KEY,
            lesson_id TEXT NOT NULL,
            parent_word_id TEXT,
            word_order INTEGER NOT NULL,
            tibetan_script TEXT NOT NULL,
            phonetic TEXT NOT NULL,
            mongolian_translation TEXT NOT NULL,
            version INTEGER DEFAULT 1,
            FOREIGN KEY (lesson_id) REFERENCES lessons(id),
            FOREIGN KEY (parent_word_id) REFERENCES lesson_words(id)
          )
        ''');
        
        AppLogger.logDatabase('Migration', 'Recreated lessons tables with new schema');
      } catch (e) {
        AppLogger.logError('DatabaseHelper', '_onUpgrade v3', e);
      }
    }

    if (oldVersion < 4) {
      // Migration to version 4: Ensure lessons table has all required columns
      // If coming from v3 that didn't have the columns properly, recreate
      try {
        // Check if title column exists by trying to query it
        await db.rawQuery('SELECT title FROM lessons LIMIT 1');
      } catch (_) {
        // Title column doesn't exist, need to recreate tables
        try {
          await db.execute('DROP TABLE IF EXISTS lesson_words');
          await db.execute('DROP TABLE IF EXISTS lessons');
          
          await db.execute('''
            CREATE TABLE lessons (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL DEFAULT 'Хичээл',
              description TEXT,
              type TEXT NOT NULL DEFAULT 'vocabulary',
              sequence_order INTEGER NOT NULL UNIQUE,
              tree_path TEXT NOT NULL,
              word_count INTEGER NOT NULL,
              version INTEGER DEFAULT 1
            )
          ''');
          
          await db.execute('''
            CREATE TABLE lesson_words (
              id TEXT PRIMARY KEY,
              lesson_id TEXT NOT NULL,
              parent_word_id TEXT,
              word_order INTEGER NOT NULL,
              tibetan_script TEXT NOT NULL,
              phonetic TEXT NOT NULL,
              mongolian_translation TEXT NOT NULL,
              version INTEGER DEFAULT 1,
              FOREIGN KEY (lesson_id) REFERENCES lessons(id)
            )
          ''');
          
          AppLogger.logDatabase('Migration', 'Recreated lessons tables for v4');
        } catch (e) {
          AppLogger.logError('DatabaseHelper', '_onUpgrade v4 recreate', e);
        }
      }
    }

    if (oldVersion < 5) {
      // Migration to version 5: Remove FK constraint on parent_word_id
      // Recreate lesson_words without the self-referencing FK
      try {
        await db.execute('DROP TABLE IF EXISTS lesson_words');
        await db.execute('DROP TABLE IF EXISTS lessons');
        
        await db.execute('''
          CREATE TABLE lessons (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL DEFAULT 'Хичээл',
            description TEXT,
            type TEXT NOT NULL DEFAULT 'vocabulary',
            sequence_order INTEGER NOT NULL UNIQUE,
            tree_path TEXT NOT NULL,
            word_count INTEGER NOT NULL,
            version INTEGER DEFAULT 1
          )
        ''');
        
        await db.execute('''
          CREATE TABLE lesson_words (
            id TEXT PRIMARY KEY,
            lesson_id TEXT NOT NULL,
            parent_word_id TEXT,
            word_order INTEGER NOT NULL,
            tibetan_script TEXT NOT NULL,
            phonetic TEXT NOT NULL,
            mongolian_translation TEXT NOT NULL,
            version INTEGER DEFAULT 1,
            FOREIGN KEY (lesson_id) REFERENCES lessons(id)
          )
        ''');
        
        AppLogger.logDatabase('Migration', 'Recreated lessons tables for v5 (no FK on parent_word_id)');
      } catch (e) {
        AppLogger.logError('DatabaseHelper', '_onUpgrade v5', e);
      }
    }

    if (oldVersion < 6) {
      // Migration to version 6: Add type column to achievements
      try {
        // Check if type column exists
        final columns = await db.rawQuery('PRAGMA table_info(achievements)');
        final hasType = columns.any((col) => col['name'] == 'type');
        
        if (!hasType) {
          await db.execute("ALTER TABLE achievements ADD COLUMN type TEXT DEFAULT 'lesson'");
          AppLogger.logDatabase('Migration', 'Added type column to achievements for v6');
        }
      } catch (e) {
        AppLogger.logError('DatabaseHelper', '_onUpgrade v6', e);
      }
    }

    if (oldVersion < 7) {
      // Migration to version 7: Add tarni_counters table for local Tarni storage
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tarni_counters (
            user_id TEXT PRIMARY KEY,
            magzushir INTEGER DEFAULT 0,
            janraisig INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_tarni_user ON tarni_counters(user_id)');
        AppLogger.logDatabase('Migration', 'Added tarni_counters table for v7');
      } catch (e) {
        AppLogger.logError('DatabaseHelper', '_onUpgrade v7', e);
      }
    }

    if (oldVersion < 8) {
      // Migration to version 8: Change tarni_counters to support multiple entries per user
      try {
        // Create new table with integer primary key
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tarni_counters_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            magzushir INTEGER DEFAULT 0,
            janraisig INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');

        // If old table exists, copy data across
        final existing = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='tarni_counters'");
        if (existing.isNotEmpty) {
          try {
            await db.execute('INSERT INTO tarni_counters_new (user_id, magzushir, janraisig, created_at) SELECT user_id, magzushir, janraisig, created_at FROM tarni_counters');
          } catch (_) {}
          try {
            await db.execute('DROP TABLE IF EXISTS tarni_counters');
          } catch (_) {}
        }

        // Rename new table
        await db.execute('ALTER TABLE tarni_counters_new RENAME TO tarni_counters');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_tarni_user ON tarni_counters(user_id)');
        AppLogger.logDatabase('Migration', 'Upgraded tarni_counters to v8 schema');
      } catch (e) {
        AppLogger.logError('DatabaseHelper', '_onUpgrade v8', e);
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> clearAllTables() async {
    final db = await database;
    final tables = [
      'user_achievements',
      'user_progress',
      'heart_state',
      'follows',
      'messages',
      'notifications',
      'leaderboard',
      'sync_queue',
      'support_messages',
      'user_settings',
      'user_profile',
    ];

    for (final table in tables) {
      await db.delete(table);
    }
  }
}
