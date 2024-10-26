package dev.eons.eons_voice_assistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.Manifest
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
	private val CHANNEL = "picovoice_wakeword_channel"
	private val REQUEST_RECORD_AUDIO_PERMISSION = 200

	private val wakewordReceiver = object : BroadcastReceiver() {
		override fun onReceive(context: Context?, intent: Intent?) {
			flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
				MethodChannel(messenger, CHANNEL).invokeMethod(
					"wakewordDetected", "Wakeword detected!"
				)
			}
		}
	}

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		requestAudioPermission() // Request audio permission on startup
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"initializeWakeword" -> {
					val accessKey = call.argument<String>("accessKey")
					initializeWakewordService(accessKey)
					result.success("Wakeword service initialized")
				}
				"stopWakeword" -> {
					stopWakewordService()
					result.success("Wakeword service stopped")
				}
				else -> result.notImplemented()
			}
		}

		// Register the BroadcastReceiver for wakeword detection notifications
		registerReceiver(wakewordReceiver, IntentFilter("dev.eons.eons_voice_assistant.WAKEWORD_DETECTED"))
	}

	private fun initializeWakewordService(accessKey: String?) {
		val intent = Intent(this, EVAAccessibilityService::class.java).apply {
			putExtra("accessKey", accessKey)
		}
		startService(intent)
		Log.i("MainActivity", "Wakeword detection service started")
	}

	private fun stopWakewordService() {
		val intent = Intent(this, EVAAccessibilityService::class.java)
		stopService(intent)
		Log.i("MainActivity", "Wakeword detection service stopped")
	}

	// Request the RECORD_AUDIO permission
	private fun requestAudioPermission() {
		if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
			!= PackageManager.PERMISSION_GRANTED) {
			ActivityCompat.requestPermissions(
				this, arrayOf(Manifest.permission.RECORD_AUDIO),
				REQUEST_RECORD_AUDIO_PERMISSION
			)
		}
	}

	// Handle the result of the permission request
	override fun onRequestPermissionsResult(
		requestCode: Int, permissions: Array<String>, grantResults: IntArray
	) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode == REQUEST_RECORD_AUDIO_PERMISSION) {
			if ((grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)) {
				Toast.makeText(this, "Audio permission granted", Toast.LENGTH_SHORT).show()
			} else {
				Toast.makeText(this, "Audio permission is required for this app to function", Toast.LENGTH_LONG).show()
			}
		}
	}

	override fun onDestroy() {
		super.onDestroy()
		unregisterReceiver(wakewordReceiver)
	}
}
