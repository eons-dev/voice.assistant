package dev.eons.eons_voice_assistant

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import ai.picovoice.porcupine.PorcupineManager
import ai.picovoice.porcupine.PorcupineManagerCallback
import android.media.MediaRecorder
import java.io.IOException

class EVAAccessibilityService : AccessibilityService() {
	private val TAG = "EVAAccessibilityService"
	private var porcupineManager: PorcupineManager? = null
	private var mediaRecorder: MediaRecorder? = null

	override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
		initializeWakeword()
		
		return START_STICKY
	}

	private fun initializeWakeword() {
		try {
			// Directly reference the .ppn files in res/raw by their resource IDs
			val ppnFilePaths = arrayOf(
				"android.resource://${packageName}/raw/eva_please_en_android_v3_0_0",
				"android.resource://${packageName}/raw/hey_eva_en_android_v3_0_0",
				"android.resource://${packageName}/raw/thanks_eva_en_android_v3_0_0"
			)

			// Reference the model file directly from res/raw as well
			val modelFilePath = "android.resource://${packageName}/raw/porcupine_params"

			val sensitivities = FloatArray(ppnFilePaths.size) { 0.5f }

			porcupineManager = PorcupineManager.Builder()
				.setKeywordPaths(ppnFilePaths)  // Use the resource URIs for .ppn files
				.setModelPath(modelFilePath)	// Use the resource URI for the model file
				.setSensitivities(sensitivities)
				.build(applicationContext, object : PorcupineManagerCallback {
					override fun invoke(keywordIndex: Int) {
						Log.i(TAG, "Wakeword detected at index: $keywordIndex")
						startRecording()
					}
				})
			porcupineManager?.start()
		} catch (e: Exception) {
			Log.e(TAG, "Failed to initialize Porcupine", e)
		}
	}


	private fun startRecording() {
		val intent = Intent("dev.eons.eons_voice_assistant.WAKEWORD_DETECTED")
		sendBroadcast(intent)

		// mediaRecorder?.release()

		// mediaRecorder = MediaRecorder()
		// mediaRecorder?.apply {
		// 	setAudioSource(MediaRecorder.AudioSource.MIC)
		// 	setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
		// 	setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
		// 	setOutputFile(filesDir.toString() + "/recorded_audio.3gp")

		// 	try {
		// 		prepare()
		// 		start()
		// 		Log.i(TAG, "Audio recording started.")
		// 	} catch (e: IOException) {
		// 		Log.e(TAG, "Recording failed", e)
		// 	}
		// }
	}

	private fun stopRecording() {
		try {
			mediaRecorder?.apply {
				stop()
				release()
				mediaRecorder = null
				Log.i(TAG, "Audio recording stopped.")
			}
			// val intent = Intent("dev.eons.eons_voice_assistant.AUDIO_RECORDED")
			// sendBroadcast(intent)
		} catch (e: RuntimeException) {
			Log.e(TAG, "Failed to stop recording", e)
		}
	}

	override fun onAccessibilityEvent(event: android.view.accessibility.AccessibilityEvent) {
		// Not required for now.
	}

	override fun onInterrupt() {
		// Handle interruptions to the service
	}
}
