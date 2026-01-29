package com.treasure.tenzin

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.URL
import java.util.Calendar
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tenzin.app/notifications"
    private val NOTIFICATION_CHANNEL_ID = "tenzin_reminders"
    private val CHAT_CHANNEL_ID = "tenzin_chat"
    private val NOTIFICATION_ID = 1001
    private val CHAT_NOTIFICATION_ID = 2001
    private val DAILY_REMINDER_REQUEST_CODE = 2001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Initialize native Appwrite client (optional) to verify connectivity
        AppwriteInitializer.init(this.applicationContext)
        
        createNotificationChannels()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    result.success(true)
                }
                "areNotificationsEnabled" -> {
                    val enabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
                    result.success(enabled)
                }
                "showTestNotification" -> {
                    val title = call.argument<String>("title") ?: "Tenzin"
                    val body = call.argument<String>("body") ?: "Test notification"
                    showNotification(title, body)
                    result.success(true)
                }
                "scheduleDailyReminder" -> {
                    val hour = call.argument<Int>("hour") ?: 19
                    val minute = call.argument<Int>("minute") ?: 0
                    val title = call.argument<String>("title") ?: "Tenzin Reminder"
                    val body = call.argument<String>("body") ?: "Time to learn!"
                    scheduleDailyReminder(hour, minute, title, body)
                    result.success(true)
                }
                "cancelDailyReminder" -> {
                    cancelDailyReminder()
                    result.success(true)
                }
                "scheduleStreakReminder" -> {
                    val title = call.argument<String>("title") ?: "Streak Reminder"
                    val body = call.argument<String>("body") ?: "Keep your streak!"
                    scheduleDailyReminder(20, 0, title, body)
                    result.success(true)
                }
                "showChatNotification" -> {
                    val senderId = call.argument<String>("senderId") ?: ""
                    val senderName = call.argument<String>("senderName") ?: "Хэрэглэгч"
                    val senderAvatarUrl = call.argument<String>("senderAvatarUrl")
                    val messagePreview = call.argument<String>("messagePreview") ?: ""
                    showChatNotification(senderId, senderName, senderAvatarUrl, messagePreview)
                    result.success(true)
                }
                "scheduleRandomizedReminders" -> {
                    val minMinutes = call.argument<Int>("minMinutes") ?: 30
                    val maxMinutes = call.argument<Int>("maxMinutes") ?: 180
                    val title = call.argument<String>("title") ?: "Тензин сануулга 📚"
                    val body = call.argument<String>("body") ?: "Хичээлийн сануулга"
                    val triggerAt = scheduleRandomizedReminder(minMinutes, maxMinutes, title, body)
                    result.success(triggerAt)
                }
                "getNextRandomizedReminder" -> {
                    val prefs = getSharedPreferences("tenzin_prefs", Context.MODE_PRIVATE)
                    val next = prefs.getLong("next_random_reminder", -1L)
                    if (next <= 0L) result.success(null) else result.success(next)
                }
                "cancelRandomizedReminders" -> {
                    cancelRandomizedReminders()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Learning reminders channel
            val reminderChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Сануулга",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Өдөр бүрийн суралцах сануулга"
            }
            notificationManager.createNotificationChannel(reminderChannel)
            
            // Chat messages channel
            val chatChannel = NotificationChannel(
                CHAT_CHANNEL_ID,
                "Мессежүүд",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Шинэ мессежийн мэдэгдэл"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(chatChannel)
        }
    }

    private fun showNotification(title: String, body: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        with(NotificationManagerCompat.from(this)) {
            try {
                notify(NOTIFICATION_ID, builder.build())
            } catch (e: SecurityException) {
                // Handle missing POST_NOTIFICATIONS permission
            }
        }
    }

    private fun showChatNotification(
        senderId: String,
        senderName: String,
        senderAvatarUrl: String?,
        messagePreview: String
    ) {
        // Intent to open chat screen with the sender
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("openChat", true)
            putExtra("chatUserId", senderId)
            putExtra("chatUserName", senderName)
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 
            senderId.hashCode(), 
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(this, CHAT_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_email)
            .setContentTitle(senderName)
            .setContentText(messagePreview)
            .setStyle(NotificationCompat.BigTextStyle().bigText(messagePreview))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)

        // Try to load avatar image asynchronously
        if (!senderAvatarUrl.isNullOrEmpty()) {
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val url = URL(senderAvatarUrl)
                    val bitmap = BitmapFactory.decodeStream(url.openConnection().getInputStream())
                    withContext(Dispatchers.Main) {
                        builder.setLargeIcon(bitmap)
                        with(NotificationManagerCompat.from(this@MainActivity)) {
                            try {
                                notify(CHAT_NOTIFICATION_ID + senderId.hashCode(), builder.build())
                            } catch (e: SecurityException) {
                                // Handle missing POST_NOTIFICATIONS permission
                            }
                        }
                    }
                } catch (e: Exception) {
                    // Failed to load avatar, show notification without it
                    withContext(Dispatchers.Main) {
                        with(NotificationManagerCompat.from(this@MainActivity)) {
                            try {
                                notify(CHAT_NOTIFICATION_ID + senderId.hashCode(), builder.build())
                            } catch (e: SecurityException) {
                                // Handle missing POST_NOTIFICATIONS permission
                            }
                        }
                    }
                }
            }
        } else {
            with(NotificationManagerCompat.from(this)) {
                try {
                    notify(CHAT_NOTIFICATION_ID + senderId.hashCode(), builder.build())
                } catch (e: SecurityException) {
                    // Handle missing POST_NOTIFICATIONS permission
                }
            }
        }
    }

    private fun scheduleDailyReminder(hour: Int, minute: Int, title: String, body: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(this, ReminderBroadcastReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            DAILY_REMINDER_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val calendar = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        alarmManager.setRepeating(
            AlarmManager.RTC_WAKEUP,
            calendar.timeInMillis,
            AlarmManager.INTERVAL_DAY,
            pendingIntent
        )
    }

    // Request codes for randomized reminders
    private val RANDOM_REMINDER_REQUEST_CODE = 3001

    private fun scheduleRandomizedReminder(minMinutes: Int, maxMinutes: Int, title: String, body: String): Long {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val randomDelayMs = computeRandomDelayMs(minMinutes, maxMinutes)
        val triggerAt = System.currentTimeMillis() + randomDelayMs

        val intent = Intent(this, ReminderBroadcastReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
            putExtra("randomized", true)
            putExtra("minMinutes", minMinutes)
            putExtra("maxMinutes", maxMinutes)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            RANDOM_REMINDER_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Use exact alarm where possible
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        }
        // persist next trigger time
        val prefs = getSharedPreferences("tenzin_prefs", Context.MODE_PRIVATE)
        prefs.edit().putLong("next_random_reminder", triggerAt).apply()

        return triggerAt
    }

    private fun cancelRandomizedReminders() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, ReminderBroadcastReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            RANDOM_REMINDER_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
        )
        pendingIntent?.let {
            alarmManager.cancel(it)
            it.cancel()
            // clear persisted next trigger
            val prefs = getSharedPreferences("tenzin_prefs", Context.MODE_PRIVATE)
            prefs.edit().remove("next_random_reminder").apply()
        }
    }

    private fun computeRandomDelayMs(minMinutes: Int, maxMinutes: Int): Long {
        val min = minMinutes.coerceAtLeast(1)
        val max = maxMinutes.coerceAtLeast(min)
        val delta = max - min
        val randomOffset = if (delta > 0) (Math.random() * (delta + 1)).toLong() else 0L
        val minutes = min + randomOffset
        return minutes * 60_000L
    }

    private fun cancelDailyReminder() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, ReminderBroadcastReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            DAILY_REMINDER_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
        )
        pendingIntent?.let {
            alarmManager.cancel(it)
            it.cancel()
        }
    }
}
