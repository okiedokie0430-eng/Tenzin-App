/// Tenzin - Tibetan Learning App
/// Main entry point
///
/// Энэ файл нь аппын эхлэх цэг юм.
/// Монгол хэл дээрх хэрэглэгчийн интерфэйстэй, Appwrite backend-тэй.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app.dart';
import 'data/data.dart';
import 'data/local/daos/lesson_dao.dart';
import 'data/services/lesson_data_loader.dart';
import 'data/services/achievement_data_loader.dart';
import 'domain/services/fcm_service.dart';
import 'core/utils/logger.dart';

void main() async {
  // Flutter binding-ийг эхлүүлэх
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase эхлүүлэх (optional - for FCM)
  try {
    await Firebase.initializeApp();
    // FCM background handler бүртгэх
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    AppLogger.info('Firebase initialized successfully');
  } catch (e) {
    AppLogger.warning('Firebase initialization failed: $e');
    // Continue without Firebase - app will work without push notifications
  }

  // Системийн UI overlay тохиргоо
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Дэлгэцийн чиглэлийг portrait болгох
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Appwrite client эхлүүлэх
  AppwriteClient();

  // Notifications disabled: skip local notification initialization

  // Локал өгөгдлийн сан эхлүүлэх
  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  // Хичээлийн өгөгдлийг asset-аас ачаалах (local-only content)
  final lessonDao = LessonDao(dbHelper);
  final lessonDataLoader = LessonDataLoader(lessonDao);
  await lessonDataLoader.loadLessonsFromAssets();

  // Шагналуудыг ачаалах (local-only content)
  final achievementDataLoader = AchievementDataLoader(dbHelper);
  await achievementDataLoader.loadAchievements();

  // Апп эхлүүлэх
  runApp(
    const ProviderScope(
      child: TenzinApp(),
    ),
  );
}
