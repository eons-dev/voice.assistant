package dev.eons.eons_voice_assistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "picovoice_wakeword_channel"

    private val wakewordReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            // Ensure `flutterEngine?.dartExecutor?.binaryMessenger` is non-null
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod(
                    "wakewordDetected", "Wakeword detected!"
                )
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Start the service when the app starts
        startService(Intent(this, EVAAccessibilityService::class.java))

        // Register the BroadcastReceiver
        registerReceiver(wakewordReceiver, IntentFilter("dev.eons.eons_voice_assistant.WAKEWORD_DETECTED"))
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(wakewordReceiver)
    }
}
