package com.treasure.tenzin

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class ReminderBroadcastReceiver : BroadcastReceiver() {
    
    private val NOTIFICATION_CHANNEL_ID = "tenzin_reminders"
    private val NOTIFICATION_ID = 1001

    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: "Тензин сануулга 📚"
        val body = intent.getStringExtra("body") ?: "Өнөөдрийн хичээлээ хийхээ мартсан уу?"
        
        showNotification(context, title, body)
        // If this was a randomized reminder, schedule the next one
        val randomized = intent.getBooleanExtra("randomized", false)
        if (randomized) {
            val minMinutes = intent.getIntExtra("minMinutes", 30)
            val maxMinutes = intent.getIntExtra("maxMinutes", 180)
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                val nextDelay = (minMinutes + Math.random() * (maxMinutes - minMinutes + 1)).toLong()
                val triggerAt = System.currentTimeMillis() + nextDelay * 60_000L

                val nextIntent = Intent(context, ReminderBroadcastReceiver::class.java).apply {
                    putExtra("title", title)
                    putExtra("body", body)
                    putExtra("randomized", true)
                    putExtra("minMinutes", minMinutes)
                    putExtra("maxMinutes", maxMinutes)
                }

                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    3001,
                    nextIntent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )

                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                } else {
                    alarmManager.setExact(android.app.AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                }
                // persist next trigger time
                try {
                    val prefs = context.getSharedPreferences("tenzin_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putLong("next_random_reminder", triggerAt).apply()
                } catch (e: Exception) {
                    // ignore persistence errors
                }
            } catch (e: Exception) {
                // ignore scheduling errors
            }
        }
    }

    private fun showNotification(context: Context, title: String, body: String) {
        val notificationIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        notificationIntent?.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        
        val pendingIntent = PendingIntent.getActivity(
            context, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        with(NotificationManagerCompat.from(context)) {
            try {
                notify(NOTIFICATION_ID, builder.build())
            } catch (e: SecurityException) {
                // Handle missing POST_NOTIFICATIONS permission
            }
        }
    }
}
