package com.youpipe.music

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.annotation.SuppressLint
import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.view.MotionEvent
import android.view.VelocityTracker
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.SeekBar
import android.widget.TextView
import com.ryanheise.audioservice.AudioService
import okhttp3.Request
import java.util.concurrent.Executors

/**
 * Resso-style lock screen player: full-bleed artwork, a clock, and the player controls, shown over
 * the keyguard while music plays (docs/playback.md, "Lock screen player").
 *
 * It only talks to the media session of audio_service's [AudioService] (the same session the
 * system media card uses), so it works without the Flutter UI. Like and Repeat are session custom
 * actions handled by YouPipeAudioHandler.customAction.
 *
 * It never unlocks by itself: "Swipe up to unlock" asks the system to dismiss the keyguard, which
 * still requires the PIN, pattern or biometrics. Nothing on this screen opens the app.
 */
class LockScreenActivity : Activity() {
    private lateinit var browser: MediaBrowserCompat
    private var controller: MediaControllerCompat? = null

    private lateinit var page: View
    private lateinit var art: ImageView
    private lateinit var title: TextView
    private lateinit var artist: TextView
    private lateinit var seek: SeekBar
    private lateinit var elapsed: TextView
    private lateinit var duration: TextView
    private lateinit var like: ImageButton
    private lateinit var play: ImageButton
    private lateinit var repeat: ImageButton
    private lateinit var wave: WavyProgressDrawable

    private val main = Handler(Looper.getMainLooper())
    private val loader = Executors.newSingleThreadExecutor()
    private var artKey: String? = null
    private var seeking = false

    private val ticker = object : Runnable {
        override fun run() {
            renderPosition()
            main.postDelayed(this, 500)
        }
    }

    /** The device was unlocked some other way (fingerprint, face): this screen has no job left. */
    private val unlocked = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = finish()
    }

    private val callback = object : MediaControllerCompat.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadataCompat?) = renderMetadata(metadata)

        override fun onPlaybackStateChanged(state: PlaybackStateCompat?) = renderState(state)

        override fun onRepeatModeChanged(repeatMode: Int) = renderRepeat(repeatMode)

        override fun onSessionDestroyed() = finish()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        }
        setContentView(R.layout.activity_lock_screen)
        layoutEdgeToEdge()

        page = findViewById(R.id.page)
        art = findViewById(R.id.art)
        title = findViewById(R.id.title)
        artist = findViewById(R.id.artist)
        seek = findViewById(R.id.seek)
        elapsed = findViewById(R.id.elapsed)
        duration = findViewById(R.id.duration)
        like = findViewById(R.id.like)
        play = findViewById(R.id.play)
        repeat = findViewById(R.id.repeat)
        wave = WavyProgressDrawable(resources.displayMetrics.density)
        seek.progressDrawable = wave

        play.setOnClickListener {
            val c = controller ?: return@setOnClickListener
            if (c.playbackState?.state == PlaybackStateCompat.STATE_PLAYING) {
                c.transportControls.pause()
            } else {
                c.transportControls.play()
            }
        }
        findViewById<View>(R.id.previous).setOnClickListener { controller?.transportControls?.skipToPrevious() }
        findViewById<View>(R.id.next).setOnClickListener { controller?.transportControls?.skipToNext() }
        like.setOnClickListener { controller?.transportControls?.sendCustomAction("toggleLike", null) }
        repeat.setOnClickListener { controller?.transportControls?.sendCustomAction("cycleRepeat", null) }
        seek.setOnSeekBarChangeListener(
            object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(bar: SeekBar, progress: Int, fromUser: Boolean) {
                    if (fromUser) elapsed.text = formatTime(progress.toLong())
                }

                override fun onStartTrackingTouch(bar: SeekBar) {
                    seeking = true
                }

                override fun onStopTrackingTouch(bar: SeekBar) {
                    seeking = false
                    controller?.transportControls?.seekTo(bar.progress.toLong())
                }
            },
        )
        setUpSwipeToUnlock(findViewById(R.id.root))

        browser =
            MediaBrowserCompat(
                this,
                ComponentName(this, AudioService::class.java),
                object : MediaBrowserCompat.ConnectionCallback() {
                    override fun onConnected() {
                        val c = MediaControllerCompat(this@LockScreenActivity, browser.sessionToken)
                        c.registerCallback(callback, main)
                        controller = c
                        renderMetadata(c.metadata)
                        renderState(c.playbackState)
                        renderRepeat(c.repeatMode)
                    }

                    override fun onConnectionFailed() = finish()
                },
                null,
            )

        val filter = IntentFilter(Intent.ACTION_USER_PRESENT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(unlocked, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(unlocked, filter)
        }
    }

    override fun onStart() {
        super.onStart()
        browser.connect()
        main.post(ticker)
    }

    override fun onResume() {
        super.onResume()
        // Opened on screen-off, but the phone was woken before the keyguard locked.
        val keyguard = getSystemService(KeyguardManager::class.java)
        val power = getSystemService(PowerManager::class.java)
        if (power.isInteractive && !keyguard.isKeyguardLocked) finish()
    }

    override fun onStop() {
        main.removeCallbacks(ticker)
        wave.playing = false
        controller?.unregisterCallback(callback)
        controller = null
        browser.disconnect()
        super.onStop()
    }

    override fun onDestroy() {
        unregisterReceiver(unlocked)
        loader.shutdownNow()
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() = unlock()

    // Rendering -----------------------------------------------------------------------------------

    private fun renderMetadata(metadata: MediaMetadataCompat?) {
        if (metadata == null) return
        title.text = metadata.getString(MediaMetadataCompat.METADATA_KEY_TITLE)
        artist.text = metadata.getString(MediaMetadataCompat.METADATA_KEY_ARTIST)
        val total = metadata.getLong(MediaMetadataCompat.METADATA_KEY_DURATION)
        seek.max = total.toInt().coerceAtLeast(0)
        duration.text = if (total > 0) formatTime(total) else ""
        val liked = metadata.getLong("liked") == 1L
        like.setImageResource(if (liked) R.drawable.ic_ls_liked else R.drawable.ic_ls_like)
        like.contentDescription = if (liked) "Remove like" else "Like"
        loadArt(metadata)
        renderPosition()
    }

    private fun renderState(state: PlaybackStateCompat?) {
        if (state == null) return
        val playing = state.state == PlaybackStateCompat.STATE_PLAYING
        play.setImageResource(if (playing) R.drawable.ic_ls_pause else R.drawable.ic_ls_play)
        play.contentDescription = if (playing) "Pause" else "Play"
        wave.playing = playing
        renderPosition()
    }

    private fun renderRepeat(mode: Int) {
        repeat.setImageResource(
            if (mode == PlaybackStateCompat.REPEAT_MODE_ONE) R.drawable.ic_ls_repeat_one else R.drawable.ic_ls_repeat,
        )
        repeat.alpha = if (mode == PlaybackStateCompat.REPEAT_MODE_NONE) 0.5f else 1f
    }

    private fun renderPosition() {
        val state = controller?.playbackState ?: return
        if (seeking) return
        var position = state.position
        if (state.state == PlaybackStateCompat.STATE_PLAYING) {
            position += ((SystemClock.elapsedRealtime() - state.lastPositionUpdateTime) * state.playbackSpeed).toLong()
        }
        if (seek.max > 0) position = position.coerceIn(0, seek.max.toLong())
        seek.progress = position.toInt()
        elapsed.text = formatTime(position)
    }

    /** Shows the session's bitmap at once, then swaps in a full-resolution copy of the artwork. */
    private fun loadArt(metadata: MediaMetadataCompat) {
        val uri = metadata.getString(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON_URI)
        val key = uri ?: metadata.getString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID)
        if (key == artKey) return
        artKey = key
        metadata.getBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART)?.let(art::setImageBitmap)
        if (uri == null) return
        loader.execute {
            val bitmap = runCatching { fetchArt(uri) }.getOrNull() ?: return@execute
            main.post { if (artKey == key) art.setImageBitmap(bitmap) }
        }
    }

    private fun fetchArt(uri: String): Bitmap? {
        val parsed = Uri.parse(uri)
        if (parsed.scheme == "file") return BitmapFactory.decodeFile(parsed.path)
        // googleusercontent artwork takes its size from the URL (=wN-hN), like YtImage.
        val url = uri.replace(Regex("=w\\d+-h\\d+"), "=w1200-h1200")
        http.newCall(Request.Builder().url(url).build()).execute().use { response ->
            if (!response.isSuccessful) return null
            return BitmapFactory.decodeStream(response.body?.byteStream())
        }
    }

    // Swipe up to unlock ---------------------------------------------------------------------------

    /** Drag the page up past a quarter of the screen (or fling it) to unlock; otherwise it springs back. */
    @SuppressLint("ClickableViewAccessibility")
    private fun setUpSwipeToUnlock(root: View) {
        var startY = 0f
        var tracker: VelocityTracker? = null
        root.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startY = event.rawY
                    tracker = VelocityTracker.obtain().also { it.addMovement(event) }
                }

                MotionEvent.ACTION_MOVE -> {
                    tracker?.addMovement(event)
                    val dy = (event.rawY - startY).coerceAtMost(0f)
                    page.translationY = dy
                    page.alpha = 1f + dy / root.height
                }

                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    tracker?.addMovement(event)
                    tracker?.computeCurrentVelocity(1000)
                    val velocity = tracker?.yVelocity ?: 0f
                    tracker?.recycle()
                    tracker = null
                    val dy = event.rawY - startY
                    if (event.actionMasked == MotionEvent.ACTION_UP && (dy < -root.height / 4f || velocity < -2000f)) {
                        unlock()
                    } else {
                        page.animate().translationY(0f).alpha(1f).setDuration(200).start()
                    }
                }
            }
            true
        }
    }

    private fun unlock() {
        page
            .animate()
            .translationY(-page.height.toFloat())
            .alpha(0f)
            .setDuration(200)
            .setListener(
                object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) = dismissKeyguard()
                },
            ).start()
    }

    /** Hands over to the system's own unlock (PIN, pattern, biometrics); cancelling brings the player back. */
    private fun dismissKeyguard() {
        val keyguard = getSystemService(KeyguardManager::class.java)
        if (!keyguard.isKeyguardLocked || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            finish()
            return
        }
        keyguard.requestDismissKeyguard(
            this,
            object : KeyguardManager.KeyguardDismissCallback() {
                override fun onDismissSucceeded() = finish()

                override fun onDismissCancelled() = restorePage()

                override fun onDismissError() = restorePage()
            },
        )
    }

    private fun restorePage() {
        page.animate().setListener(null).translationY(0f).alpha(1f).setDuration(200).start()
    }

    // Layout ----------------------------------------------------------------------------------------

    /** Draws behind the status and navigation bars, padding the controls clear of them. */
    private fun layoutEdgeToEdge() {
        val content = findViewById<View>(R.id.content)
        val start = content.paddingStart
        val end = content.paddingEnd
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }
        content.setOnApplyWindowInsetsListener { view, insets ->
            val (top, bottom) =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    val bars = insets.getInsets(WindowInsets.Type.systemBars())
                    bars.top to bars.bottom
                } else {
                    @Suppress("DEPRECATION")
                    insets.systemWindowInsetTop to insets.systemWindowInsetBottom
                }
            view.setPadding(start, top, end, bottom)
            insets
        }
    }

    companion object {
        // Shares the app's connection pool and dispatcher threads.
        private val http = Googlevideo.client

        private fun formatTime(ms: Long): String {
            val seconds = ms / 1000
            return "%d:%02d".format(seconds / 60, seconds % 60)
        }
    }
}
