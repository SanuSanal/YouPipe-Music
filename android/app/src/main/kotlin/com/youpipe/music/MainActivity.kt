package com.youpipe.music

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        StreamExtractorChannel.register(flutterEngine.dartExecutor.binaryMessenger)
        DownloadChannel.register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
