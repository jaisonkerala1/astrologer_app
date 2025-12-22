package com.example.astrologer_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.media.RingtoneManager

/**
 * WhatsApp-style incoming call ringing for Android 12+:
 * - Runs as a foreground service
 * - Plays the user's current system ringtone in a loop
 * - Owns the CallStyle notification
 * - Stops immediately on accept/decline/tap/cancel/end/timeout
 */
class CallRingtoneService : Service() {

    companion object {
        private const val CHANNEL_ID = "calls_native"
        private const val CHANNEL_NAME = "Calls (Native)"

        private const val ACTION_START = "START"
        private const val ACTION_STOP = "STOP"

        private const val EXTRA_CALL_ID = "call_id"
        private const val EXTRA_CALLER_NAME = "caller_name"
        private const val EXTRA_IS_VIDEO = "call_is_video"
        private const val EXTRA_CALLER_ID = "caller_id"
        private const val EXTRA_CALLER_TYPE = "caller_type"
        private const val EXTRA_CHANNEL_NAME = "channel_name"
        private const val EXTRA_AGORA_TOKEN = "agora_token"
        private const val EXTRA_AGORA_APP_ID = "agora_app_id"

        private const val RING_TIMEOUT_MS = 45_000L

        @Volatile
        private var currentCallId: String? = null
    }

    private var mediaPlayer: MediaPlayer? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioManager.OnAudioFocusChangeListener? = null
    private val handler = Handler(Looper.getMainLooper())
    private var timeoutRunnable: Runnable? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        // This implementation is Android 12+ only (CallStyle is API 31+).
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            stopSelf()
            return START_NOT_STICKY
        }

        try {
            when (intent.action) {
                ACTION_START -> {
                    android.util.Log.d("CallRingtoneService", "🔔 START action received")
                    startRinging(intent)
                }
                ACTION_STOP -> {
                    val callId = intent.getStringExtra(EXTRA_CALL_ID)
                    android.util.Log.d("CallRingtoneService", "🛑 STOP action received for callId: $callId")
                    stopRinging(callId)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("CallRingtoneService", "❌ Exception in onStartCommand: $e")
            // Defensive: never crash the app due to service start failures.
            try {
                stopMediaPlayerRingtone()
            } catch (_: Exception) {
            }
            try {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } catch (_: Exception) {
            }
            currentCallId = null
            stopSelf()
        }

        // Keep running until explicitly stopped or timeout.
        return START_STICKY
    }

    private fun startRinging(intent: Intent) {
        val callId = intent.getStringExtra(EXTRA_CALL_ID) ?: return
        val callerName = intent.getStringExtra(EXTRA_CALLER_NAME) ?: "Incoming call"
        val isVideo = intent.getBooleanExtra(EXTRA_IS_VIDEO, false)

        // Replace any previous call.
        if (currentCallId != null && currentCallId != callId) {
            stopRinging(null)
        }
        currentCallId = callId

        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createSilentCallChannel(notificationManager)

        val notificationId = callId.hashCode()
        val notification = buildCallStyleNotification(
            callId = callId,
            callerName = callerName,
            isVideo = isVideo,
            callerId = intent.getStringExtra(EXTRA_CALLER_ID) ?: "",
            callerType = intent.getStringExtra(EXTRA_CALLER_TYPE) ?: "",
            channelName = intent.getStringExtra(EXTRA_CHANNEL_NAME) ?: "",
            agoraToken = intent.getStringExtra(EXTRA_AGORA_TOKEN) ?: "",
            agoraAppId = intent.getStringExtra(EXTRA_AGORA_APP_ID) ?: ""
        )

        // IMPORTANT (Android 10+ / targetSdk 34+):
        // Specify the foreground service type to avoid runtime exceptions on newer Android versions.
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    notificationId,
                    notification,
                    // Android 14+/16 restriction:
                    // phoneCall FGS requires Dialer role / MANAGE_OWN_CALLS, which we don't have.
                    // Use mediaPlayback so we can legally play ringtone in background.
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else {
                startForeground(notificationId, notification)
            }
        } catch (_: Exception) {
            // If we can't become a foreground service, don't crash the app.
            // Best-effort: show the notification (non-FGS) and stop.
            try {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(notificationId, notification)
            } catch (_: Exception) {
            }
            currentCallId = null
            stopSelf()
            return
        }

        startMediaPlayerRingtone()
        scheduleTimeout(callId)
    }

    private fun stopRinging(callId: String?) {
        android.util.Log.d("CallRingtoneService", "🔇 stopRinging called for callId: $callId, currentCallId: $currentCallId")
        val current = currentCallId
        if (callId != null && current != null && callId != current) {
            // Not our call; ignore.
            android.util.Log.d("CallRingtoneService", "⏭️ Ignoring stop request (different call)")
            return
        }

        android.util.Log.d("CallRingtoneService", "✅ Stopping ringtone service")
        cancelTimeout()
        stopMediaPlayerRingtone()

        // Remove foreground notification.
        stopForeground(STOP_FOREGROUND_REMOVE)
        currentCallId = null

        stopSelf()
        android.util.Log.d("CallRingtoneService", "✅ Service stopped")
    }

    private fun scheduleTimeout(callId: String) {
        cancelTimeout()
        timeoutRunnable = Runnable {
            // Timeout reached: stop ringing (WhatsApp-like).
            stopRinging(callId)
            // Also ensure notification is cancelled.
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(callId.hashCode())
        }.also { handler.postDelayed(it, RING_TIMEOUT_MS) }
    }

    private fun cancelTimeout() {
        timeoutRunnable?.let { handler.removeCallbacks(it) }
        timeoutRunnable = null
    }

    private fun startMediaPlayerRingtone() {
        stopMediaPlayerRingtone()

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val am = audioManager ?: return

        // Acquire audio focus for ringtone usage.
        audioFocusRequest = AudioManager.OnAudioFocusChangeListener { /* ignore */ }
        @Suppress("DEPRECATION")
        am.requestAudioFocus(
            audioFocusRequest,
            AudioManager.STREAM_RING,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
        )

        val ringtoneUri: Uri = try {
            RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_RINGTONE)
                ?: Settings.System.DEFAULT_RINGTONE_URI
        } catch (_: Exception) {
            Settings.System.DEFAULT_RINGTONE_URI
        }

        try {
            val mp = MediaPlayer()
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            mp.setAudioAttributes(attrs)
            mp.setDataSource(this, ringtoneUri)
            mp.isLooping = true
            mp.prepare()
            mp.start()
            mediaPlayer = mp
        } catch (_: Exception) {
            // If ringtone can't be played, just keep notification visible.
        }
    }

    private fun stopMediaPlayerRingtone() {
        try {
            mediaPlayer?.stop()
        } catch (_: Exception) {
        }
        try {
            mediaPlayer?.release()
        } catch (_: Exception) {
        }
        mediaPlayer = null

        // Release audio focus.
        val am = audioManager
        val listener = audioFocusRequest
        if (am != null && listener != null) {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(listener)
        }
        audioFocusRequest = null
        audioManager = null
    }

    override fun onDestroy() {
        cancelTimeout()
        stopMediaPlayerRingtone()
        super.onDestroy()
    }

    private fun buildCallStyleNotification(
        callId: String,
        callerName: String,
        isVideo: Boolean,
        callerId: String,
        callerType: String,
        channelName: String,
        agoraToken: String,
        agoraAppId: String
    ): Notification {
        // Tap opens IncomingCallScreen
        val tapIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_action", "tap")
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("call_is_video", isVideo)
            putExtra("caller_id", callerId)
            putExtra("caller_type", callerType)
            putExtra("channel_name", channelName)
            putExtra("agora_token", agoraToken)
            putExtra("agora_app_id", agoraAppId)
        }

        val acceptIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_action", "accept")
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("call_is_video", isVideo)
            putExtra("caller_id", callerId)
            putExtra("caller_type", callerType)
            putExtra("channel_name", channelName)
            putExtra("agora_token", agoraToken)
            putExtra("agora_app_id", agoraAppId)
        }

        val declineIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_action", "decline")
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("call_is_video", isVideo)
            putExtra("caller_id", callerId)
            putExtra("caller_type", callerType)
            putExtra("channel_name", channelName)
            putExtra("agora_token", agoraToken)
            putExtra("agora_app_id", agoraAppId)
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

        val person = android.app.Person.Builder().setName(callerName).build()
        val callStyle = Notification.CallStyle.forIncomingCall(
            person,
            declinePendingIntent,
            acceptPendingIntent
        ).setIsVideo(isVideo)

        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle(callerName)
            .setContentText(if (isVideo) "Incoming Video Call" else "Incoming Voice Call")
            .setSmallIcon(getSmallIcon())
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_CALL)
            .setContentIntent(tapPendingIntent)
            .setFullScreenIntent(tapPendingIntent, true)
            .setStyle(callStyle)
            .setColor(Color.parseColor("#25D366"))
            .setColorized(true)
            .setAutoCancel(false)
            .setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            .setPriority(Notification.PRIORITY_MAX)
            .build()
    }

    private fun createSilentCallChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val existing = notificationManager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Incoming calls with full-screen intent (ringtone played by service)"
            enableVibration(true)
            enableLights(true)
            lightColor = Color.parseColor("#25D366")
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            // IMPORTANT: silent channel so we don't get a one-shot notification sound.
            setSound(null, null)
        }
        notificationManager.createNotificationChannel(channel)
    }

    private fun getSmallIcon(): Int {
        val resId = resources.getIdentifier("ic_stat_call", "drawable", packageName)
        return if (resId != 0) resId else android.R.drawable.sym_call_incoming
    }
}








