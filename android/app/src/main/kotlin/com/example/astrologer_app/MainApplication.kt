package com.example.astrologer_app

import android.app.Activity
import android.app.Application
import android.os.Bundle

/**
 * Custom Application class to reliably track whether the app is in foreground.
 * This is used by MyFirebaseMessagingService to determine whether to show
 * the native call notification or let Flutter's in-app UI handle it.
 */
class MainApplication : Application(), Application.ActivityLifecycleCallbacks {

    companion object {
        @Volatile
        private var activityCount = 0

        /**
         * Returns true if at least one activity is currently visible (app in foreground).
         * This is more reliable than checking runningAppProcesses on Android 12+.
         */
        fun isAppInForeground(): Boolean {
            return activityCount > 0
        }
    }

    override fun onCreate() {
        super.onCreate()
        registerActivityLifecycleCallbacks(this)
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
    override fun onActivityStarted(activity: Activity) {
        activityCount++
    }

    override fun onActivityResumed(activity: Activity) {}
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityStopped(activity: Activity) {
        activityCount--
    }

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityDestroyed(activity: Activity) {}
}






