package com.example.kasir_toko

import android.media.ToneGenerator
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kasir_toko/beep"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "beep") {
                    try {
                        val toneGen = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
                        toneGen.startTone(ToneGenerator.TONE_PROP_BEEP, 150)
                        Thread.sleep(150)
                        toneGen.release()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
