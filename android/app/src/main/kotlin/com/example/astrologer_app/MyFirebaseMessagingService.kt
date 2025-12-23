package com.example.astrologer_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val CHANNEL_ID = "calls_native"
        private const val CHANNEL_NAME = "Calls (Native)"
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val type = message.data["type"] ?: return
        when (type) {
            "call", "voice_call", "video_call" -> {
                // If the app is already open/visible, do NOT show the heads-up CallStyle notification.
                // Flutter/Socket already handles showing the in-app incoming call UI.
                val isInForeground = MainApplication.isAppInForeground()
                android.util.Log.d("FCM", "📞 Call FCM received. App foreground: $isInForeground")
                if (isInForeground) {
                    android.util.Log.d("FCM", "✅ App in foreground - skipping native notification (Flutter handles it)")
                    return
                }
                val callerName = message.data["callerName"] ?: "Incoming call"
                val callId = message.data["callId"] ?: "call"
                val isVideo = type == "video_call"
                android.util.Log.d("FCM", "📱 App in background - starting ringtone service")
                // WhatsApp-style ringing: start foreground ringtone service (Android 12+).
                startRingtoneService(callerName, callId, isVideo, message.data)
            }
            "call_cancel", "call_end" -> {
                val callId = message.data["callId"] ?: "call"
                android.util.Log.d("FCM", "📴 Call cancel/end - stopping ringtone service")
                stopRingtoneService(callId)
                cancelCallNotification(callId)
            }
        }
    }

    private fun startRingtoneService(
        callerName: String,
        callId: String,
        isVideo: Boolean,
        data: Map<String, String>
    ) {
        // Android 12+ only
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return

        val serviceIntent = Intent(this, CallRingtoneService::class.java).apply {
            action = "START"
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("call_is_video", isVideo)
            putExtra("caller_id", data["callerId"] ?: "")
            putExtra("caller_type", data["callerType"] ?: "")
            putExtra("channel_name", data["channelName"] ?: "")
            putExtra("agora_token", data["agoraToken"] ?: "")
            putExtra("agora_app_id", data["agoraAppId"] ?: "")
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        } catch (_: Exception) {
            // If service start fails for any reason, fall back to just showing notification.
            showCallStyleNotification(callerName, callId, isVideo, data)
        }
    }

    private fun stopRingtoneService(callId: String) {
        val stopIntent = Intent(this, CallRingtoneService::class.java).apply {
            action = "STOP"
            putExtra("call_id", callId)
        }
        try {
            startService(stopIntent)
        } catch (_: Exception) {
            // ignore
        }
    }

    private fun showCallStyleNotification(
        callerName: String,
        callId: String,
        isVideo: Boolean,
        data: Map<String, String>
    ) {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        createCallChannel(notificationManager)

        // If CallStyle not available (pre-Android 12), skip to avoid showing legacy style.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return

        // Intent for tapping notification body - opens IncomingCallScreen
        val tapIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_action", "tap")
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("call_is_video", isVideo)
            putExtra("caller_id", data["callerId"] ?: "")
            putExtra("caller_type", data["callerType"] ?: "")
            putExtra("channel_name", data["channelName"] ?: "")
            putExtra("agora_token", data["agoraToken"] ?: "")
            putExtra("agora_app_id", data["agoraAppId"] ?: "")
        }

        val acceptIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_action", "accept")
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("call_is_video", isVideo)
            putExtra("caller_id", data["callerId"] ?: "")
            putExtra("caller_type", data["callerType"] ?: "")
            putExtra("channel_name", data["channelName"] ?: "")
            putExtra("agora_token", data["agoraToken"] ?: "")
            putExtra("agora_app_id", data["agoraAppId"] ?: "")
        }

        val declineIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_action", "decline")
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("call_is_video", isVideo)
            putExtra("caller_id", data["callerId"] ?: "")
            putExtra("caller_type", data["callerType"] ?: "")
            putExtra("channel_name", data["channelName"] ?: "")
            putExtra("agora_token", data["agoraToken"] ?: "")
            putExtra("agora_app_id", data["agoraAppId"] ?: "")
        }

        val tapPendingIntent = PendingIntent.getActivity(
            this,
            2,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val acceptPendingIntent = PendingIntent.getActivity(
            this,
            0,
            acceptIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val declinePendingIntent = PendingIntent.getActivity(
            this,
            1,
            declineIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val person = android.app.Person.Builder()
            .setName(callerName)
            .build()

        val callStyle = Notification.CallStyle.forIncomingCall(
            person,
            declinePendingIntent,
            acceptPendingIntent
        ).setIsVideo(isVideo)

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle(callerName)
            .setContentText(if (isVideo) "Incoming Video Call" else "Incoming Voice Call")
            .setSmallIcon(getSmallIcon())
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_CALL)
            .setContentIntent(tapPendingIntent) // Tap notification body → IncomingCallScreen
            .setFullScreenIntent(tapPendingIntent, true) // Full-screen also shows IncomingCallScreen
            .setStyle(callStyle)
            .setColor(Color.parseColor("#0F172A")) // Professional dark slate
            .setColorized(true)
            .setAutoCancel(false)
            .setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            .setPriority(Notification.PRIORITY_MAX)

        notificationManager.notify(callId.hashCode(), builder.build())
    }

    private fun cancelCallNotification(callId: String) {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(callId.hashCode())
    }

    private fun createCallChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val existing = notificationManager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Incoming calls with full-screen intent"
                    enableVibration(true)
                    enableLights(true)
                    lightColor = Color.parseColor("#25D366")
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    // IMPORTANT: silent channel so we don't get a one-shot notification sound.
                    setSound(null, null)
                }
                notificationManager.createNotificationChannel(channel)
            }
        }
    }

    private fun getSmallIcon(): Int {
        val resId = resources.getIdentifier("ic_stat_call", "drawable", packageName)
        return if (resId != 0) resId else android.R.drawable.sym_call_incoming
    }
}


