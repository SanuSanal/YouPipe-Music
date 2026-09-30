package com.youpipe.music

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.PlaybackStateCompat
import com.ryanheise.audioservice.AudioService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Opens [LockScreenActivity] when the screen turns off while music plays, so it is already there
 * when the phone wakes up (as in Resso).
 *
 * Android 10+ only lets a background app start an activity with "Display over other apps"
 * (SYSTEM_ALERT_WINDOW), so the launch also needs that permission, plus the "Lock screen player"
 * setting (the `lockScreenPlayer` key that shared_preferences stores as `flutter.lockScreenPlayer`).
 * Without them nothing happens and the system media card stays as it is.
 */
object LockScreenLauncher {
    private var context: Context? = null
    private var browser: MediaBrowserCompat? = null
    private var controller: MediaControllerCompat? = null

    private val screenOff =
        object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (!enabled(context) || !Settings.canDrawOverlays(context)) return
                if (controller?.playbackState?.state != PlaybackStateCompat.STATE_PLAYING) return
                context.startActivity(
                    Intent(context, LockScreenActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION),
                )
            }
        }

    fun register(
        activityContext: Context,
        messenger: BinaryMessenger,
    ) {
        val app = activityContext.applicationContext
        MethodChannel(messenger, "youpipe/lockscreen").setMethodCallHandler { call, result ->
            when (call.method) {
                "canDrawOverlays" -> result.success(Settings.canDrawOverlays(app))
                "requestOverlay" -> {
                    val intent =
                        Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:${app.packageName}"))
                    activityContext.startActivity(intent)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
        if (context == null) {
            context = app
            val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                app.registerReceiver(screenOff, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                app.registerReceiver(screenOff, filter)
            }
        }
        if (controller == null) connect(app)
    }

    /** Follows the playing state through audio_service's media session. */
    private fun connect(app: Context) {
        browser?.disconnect()
        lateinit var b: MediaBrowserCompat
        b =
            MediaBrowserCompat(
                app,
                ComponentName(app, AudioService::class.java),
                object : MediaBrowserCompat.ConnectionCallback() {
                    override fun onConnected() {
                        controller = MediaControllerCompat(app, b.sessionToken)
                    }

                    override fun onConnectionSuspended() {
                        controller = null
                    }

                    override fun onConnectionFailed() {
                        controller = null
                    }
                },
                null,
            )
        browser = b
        b.connect()
    }

    private fun enabled(context: Context) =
        context
            .getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getBoolean("flutter.lockScreenPlayer", false)
}
