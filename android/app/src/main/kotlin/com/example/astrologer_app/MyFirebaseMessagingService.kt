package com.example.astrologer_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
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
                val callerName = message.data["callerName"] ?: "Incoming call"
                val callId = message.data["callId"] ?: "call"
                val isVideo = type == "video_call"
                showCallStyleNotification(callerName, callId, isVideo, message.data)
            }
            "call_cancel", "call_end" -> {
                val callId = message.data["callId"] ?: "call"
                cancelCallNotification(callId)
            }
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
            .setColor(Color.parseColor("#25D366")) // WhatsApp green
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


