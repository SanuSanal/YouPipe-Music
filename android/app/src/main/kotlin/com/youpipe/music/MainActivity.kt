package com.youpipe.music

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        StreamExtractorChannel.register(flutterEngine.dartExecutor.binaryMessenger)
        DownloadChannel.register(flutterEngine.dartExecutor.binaryMessenger)
        CookieChannel.register(flutterEngine.dartExecutor.binaryMessenger)
        UpdateChannel(this).register(flutterEngine.dartExecutor.binaryMessenger)
        LockScreenLauncher.register(this, flutterEngine.dartExecutor.binaryMessenger)
        CastChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onResume() {
        super.onResume()
        CastChannel.setForeground(true)
    }

    override fun onPause() {
        CastChannel.setForeground(false)
        super.onPause()
    }
}
