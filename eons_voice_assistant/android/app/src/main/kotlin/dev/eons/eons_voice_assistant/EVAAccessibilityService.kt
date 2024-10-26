package dev.eons.eons_voice_assistant

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import ai.picovoice.porcupine.PorcupineManager
import ai.picovoice.porcupine.PorcupineManagerCallback
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class EVAAccessibilityService : AccessibilityService() {
	private val TAG = "EVAAccessibilityService"
	private var porcupineManager: PorcupineManager? = null
	private var isInitialized = false

	override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
		Log.i(TAG, "EVAAccessibilityService starting")

		val action = intent.action
		val accessKey = intent.getStringExtra("accessKey")

		if (accessKey != null) {
			initializeWakeword(accessKey)
		} else {
			Log.e(TAG, "Access key is missing, cannot start wakeword detection.")
		}
		return START_STICKY
	}

	// Stop wakeword detection when service is destroyed
	override fun onDestroy() {
		super.onDestroy()
		stopWakewordDetection()
	}


	private fun initializeWakeword(accessKey: String) {
		if (isInitialized) {
			Log.i(TAG, "Wakeword detection is already initialized")
			return
		}

		try {
			Log.i(TAG, "Initializing wakeword detection with access key")
			Log.i(TAG, "Access key used: $accessKey")

			// Copy .ppn files from res/raw to internal storage and store the paths
			val ppnFilePaths = arrayOf(
				copyRawResourceToFile(R.raw.eva_please_en_android_v3_0_0, "eva_please_en_android_v3_0_0.ppn"),
				copyRawResourceToFile(R.raw.hey_eva_en_android_v3_0_0, "hey_eva_en_android_v3_0_0.ppn"),
				copyRawResourceToFile(R.raw.thanks_eva_en_android_v3_0_0, "thanks_eva_en_android_v3_0_0.ppn")
			)
			Log.i(TAG, "PPN file paths loaded: ${ppnFilePaths.joinToString(", ")}")

			// Copy model file from res/raw to internal storage and get its path
			val modelFilePath = copyRawResourceToFile(R.raw.porcupine_params, "porcupine_params.pv")
			Log.i(TAG, "Model file path: $modelFilePath")

			val sensitivities = FloatArray(ppnFilePaths.size) { 0.5f }

			// Initialize Porcupine with model and keyword paths
			porcupineManager = PorcupineManager.Builder()
				.setAccessKey(accessKey)
				.setKeywordPaths(ppnFilePaths)
				.setModelPath(modelFilePath)
				.setSensitivities(sensitivities)
				.build(applicationContext, object : PorcupineManagerCallback {
					override fun invoke(keywordIndex: Int) {
						Log.i(TAG, "Wakeword detected at index: $keywordIndex")
						onWakewordDetected()
					}
				})
			porcupineManager?.start()
			isInitialized = true
			Log.i(TAG, "PorcupineManager started successfully")
		} catch (e: Exception) {
			Log.e(TAG, "Failed to initialize Porcupine", e)
		}
	}

	private fun stopWakewordDetection() {
		try {
			porcupineManager?.stop()
			porcupineManager = null
			isInitialized = false
			Log.i(TAG, "PorcupineManager stopped and resources released")
		} catch (e: Exception) {
			Log.e(TAG, "Error stopping PorcupineManager", e)
		}
	}

	// Handle wakeword detection event
	private fun onWakewordDetected() {
		Log.i(TAG, "Broadcasting wakeword detection intent")
		val intent = Intent("dev.eons.eons_voice_assistant.WAKEWORD_DETECTED")
		sendBroadcast(intent)
	}

	// Helper function to copy raw resource to a file in internal storage and return its path
	private fun copyRawResourceToFile(rawResId: Int, fileName: String): String {
		val file = File(filesDir, fileName)
		try {
			resources.openRawResource(rawResId).use { inputStream ->
				FileOutputStream(file).use { outputStream ->
					inputStream.copyTo(outputStream)
				}
			}
			Log.i(TAG, "Copied $fileName to internal storage at ${file.absolutePath}")
		} catch (e: IOException) {
			Log.e(TAG, "Error copying $fileName to internal storage", e)
		}
		return file.absolutePath
	}

	// Accessibility event handler (not required in this implementation)
	override fun onAccessibilityEvent(event: android.view.accessibility.AccessibilityEvent) {}

	// Handle interruptions to the service
	override fun onInterrupt() {
		Log.i(TAG, "Service interrupted")
	}
}
