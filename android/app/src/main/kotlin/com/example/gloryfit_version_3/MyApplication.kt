package com.example.gloryfit_version_3 // Make sure this package name matches your project

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // The ID of the channel. Must match the ID used in your Dart code.
            val channelId = "gloryfit_steps"
            // The user-visible name of the channel.
            val channelName = "GloryFit Steps"
            // The importance level of the notification.
            val importance = NotificationManager.IMPORTANCE_LOW // Use LOW to avoid sound/vibration

            // Create the notification channel object
            val channel = NotificationChannel(channelId, channelName, importance)
            channel.description = "Notification channel for background step tracking."

            // Get the NotificationManager system service
            val notificationManager = getSystemService(NotificationManager::class.java)

            // Register the channel with the system
            notificationManager.createNotificationChannel(channel)
        }
    }
}