package com.example.astrologer_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_ID = "calls_native"
        private const val CHANNEL_NAME = "Calls (Native)"
        private const val METHOD_CHANNEL = "com.example.astrologer_app/call_notifications"

        // Cold-start reliability:
        // If the app is force-stopped, the notification tap/accept/decline intent can arrive
        // before Flutter registers its MethodChannel handler. We store the intent payload here
        // and allow Flutter to fetch it after initialization.
        @Volatile
        private var pendingCallIntent: Map<String, Any?>? = null
    }

    private var callChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Ensure channel exists early for heads-up
        createCallChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        callChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "showCallStyleNotification" -> {
                        val callerName = call.argument<String>("callerName") ?: "Incoming call"
                        val callId = call.argument<String>("callId") ?: "call"
                        val isVideo = call.argument<Boolean>("isVideo") ?: false
                        showCallStyleNotification(callerName, callId, isVideo)
                        result.success(null)
                    }

                    "cancelCallNotification" -> {
                        val callId = call.argument<String>("callId") ?: "call"
                        cancelCallNotification(callId)
                        result.success(null)
                    }

                    "getPendingCallIntent" -> {
                        // Return once, then consume it.
                        val pending = pendingCallIntent
                        pendingCallIntent = null
                        result.success(pending)
                    }

                    else -> result.notImplemented()
                }
            }
        }

        // Deliver any pending call action to Flutter when activity starts
        deliverCallIntentToFlutter(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Replace any previous pending call intent with the newest one.
        // (Avoid stale call actions being consumed later.)
        // Note: deliverCallIntentToFlutter() will store again if it's a call intent.
        deliverCallIntentToFlutter(intent)
    }

    private fun showCallStyleNotification(callerName: String, callId: String, isVideo: Boolean) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            // CallStyle requires Android 12+
            return
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createCallChannel()

        // Pending intents for actions - bring app to foreground with extras
        val acceptIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_action", "accept")
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("call_is_video", isVideo)
            putExtra("caller_id", "")
            putExtra("caller_type", "")
            putExtra("channel_name", "")
            putExtra("agora_token", "")
            putExtra("agora_app_id", "")
        }

        val declineIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_action", "decline")
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("call_is_video", isVideo)
            putExtra("caller_id", "")
            putExtra("caller_type", "")
            putExtra("channel_name", "")
            putExtra("agora_token", "")
            putExtra("agora_app_id", "")
        }

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
            .setFullScreenIntent(acceptPendingIntent, true)
            .setStyle(callStyle)
            .setColor(Color.parseColor("#25D366")) // WhatsApp green accent
            .setColorized(true)
            .setAutoCancel(false)
            .setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            .setPriority(Notification.PRIORITY_MAX)

        notificationManager.notify(callId.hashCode(), builder.build())
    }

    private fun deliverCallIntentToFlutter(intent: Intent?) {
        if (intent == null) return
        val action = intent.getStringExtra("call_action") ?: return
        val callId = intent.getStringExtra("call_id") ?: ""

        // WhatsApp-style: stop ringing immediately on any user interaction.
        // (Tap body / Accept / Decline)
        try {
            val stopIntent = Intent(this, CallRingtoneService::class.java).apply {
                this.action = "STOP"
                putExtra("call_id", callId)
            }
            startService(stopIntent)
        } catch (_: Exception) {
            // ignore
        }
        
        // Cancel notification immediately when user interacts with it
        if (callId.isNotEmpty()) {
            cancelCallNotification(callId)
        }

        // Build payload and store it for cold start reliability (WhatsApp-style).
        val payload: Map<String, Any?> = mapOf(
            "action" to action,
            "callId" to callId,
            "callerName" to (intent.getStringExtra("caller_name") ?: ""),
            "isVideo" to (intent.getBooleanExtra("call_is_video", false)),
            "callerId" to (intent.getStringExtra("caller_id") ?: ""),
            "callerType" to (intent.getStringExtra("caller_type") ?: ""),
            "channelName" to (intent.getStringExtra("channel_name") ?: ""),
            "agoraToken" to (intent.getStringExtra("agora_token") ?: ""),
            "agoraAppId" to (intent.getStringExtra("agora_app_id") ?: ""),
            // Used to prevent stale calls being processed on next launch.
            "receivedAtMs" to System.currentTimeMillis()
        )

        pendingCallIntent = payload

        // Try immediate delivery (works when Flutter is already running).
        // If the channel isn't ready yet, Flutter will fetch pendingCallIntent later.
        try {
            callChannel?.invokeMethod("call_intent", payload)
            // Delivered successfully, consume immediately.
            pendingCallIntent = null
        } catch (_: Exception) {
            // Channel may not be ready yet - keep pendingCallIntent for later.
        }
        
        // Clear the intent extras so they don't trigger again
        intent.removeExtra("call_action")
        intent.removeExtra("call_id")
    }

    private fun cancelCallNotification(callId: String) {
        android.util.Log.d("MainActivity", "🔕 cancelCallNotification called for: $callId")
        // Also stop the ringtone foreground service so the ongoing notification disappears
        // when the user accepts/rejects from the in-app full-screen UI.
        try {
            val stopIntent = Intent(this, CallRingtoneService::class.java).apply {
                action = "STOP"
                putExtra("call_id", callId)
            }
            startService(stopIntent)
            android.util.Log.d("MainActivity", "✅ Sent STOP intent to CallRingtoneService")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "❌ Failed to stop ringtone service: $e")
        }

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(callId.hashCode())
        android.util.Log.d("MainActivity", "✅ Cancelled notification ID: ${callId.hashCode()}")
    }

    private fun createCallChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
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
        // Reuse existing monochrome status-bar icon
        val resId = resources.getIdentifier("ic_stat_call", "drawable", packageName)
        return if (resId != 0) resId else android.R.drawable.sym_call_incoming
    }
}
