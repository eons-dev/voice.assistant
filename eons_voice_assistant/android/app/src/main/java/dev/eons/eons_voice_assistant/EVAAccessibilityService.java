import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.util.Log;

import ai.picovoice.porcupine.PorcupineManager;
import ai.picovoice.porcupine.PorcupineManagerCallback;
import android.media.MediaRecorder;
import java.io.IOException;

public class EVAAccessibilityService extends AccessibilityService {
    private static final String TAG = "EVAAccessibilityService";
    private PorcupineManager porcupineManager;
    private MediaRecorder mediaRecorder;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String apiKey = intent.getStringExtra("apiKey");
        String wakewordPath = intent.getStringExtra("wakewordPath");
        String serverUrl = intent.getStringExtra("serverUrl");
        
        initializeWakeword(apiKey, wakewordPath);
        
        return START_STICKY;
    }

    private void initializeWakeword(String apiKey, String wakewordPath) {
        try {
            porcupineManager = new PorcupineManager.Builder()
                    // .setAccessKey(apiKey)
                    .setKeywordPath(wakewordPath)
                    .setSensitivity(0.5f)
                    .build(getApplicationContext(), new PorcupineManagerCallback() {
                        @Override
                        public void invoke(int keywordIndex) {
                            if (keywordIndex == 0) {
                                Log.i(TAG, "Wakeword detected!");
                                startRecording();
                            }
                        }
                    });
            porcupineManager.start();
        } catch (Exception e) {
            Log.e(TAG, "Failed to initialize Porcupine", e);
        }
    }

    private void startRecording() {
        if (mediaRecorder != null) {
            mediaRecorder.release();
        }
    
        mediaRecorder = new MediaRecorder();
        mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
        mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
        mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
        mediaRecorder.setOutputFile(getFilesDir() + "/recorded_audio.3gp");
    
        try {
            mediaRecorder.prepare();
            mediaRecorder.start();
            Log.i("EVAAccessibilityService", "Audio recording started.");
        } catch (IOException e) {
            Log.e("EVAAccessibilityService", "Recording failed", e);
        }
    }
    
    private void stopRecording() {
        if (mediaRecorder != null) {
            try {
                mediaRecorder.stop();
                mediaRecorder.release();
                mediaRecorder = null;
                Log.i("EVAAccessibilityService", "Audio recording stopped.");
            } catch (RuntimeException e) {
                Log.e("EVAAccessibilityService", "Failed to stop recording", e);
            }
        }
    }

    @Override
    public void onAccessibilityEvent(android.view.accessibility.AccessibilityEvent event) {
        // Not required for now.
    }

    @Override
    public void onInterrupt() {
        // Handle interruptions to the service
    }
}
