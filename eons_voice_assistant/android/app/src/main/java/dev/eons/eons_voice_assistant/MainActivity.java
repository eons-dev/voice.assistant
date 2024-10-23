import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "picovoice_wakeword_channel";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("initializeWakeword")) {
                        String apiKey = call.argument("apiKey");
                        String wakewordPath = call.argument("wakewordPath");
                        String serverUrl = call.argument("serverUrl");

                        initializeWakewordService(apiKey, wakewordPath, serverUrl);
                        result.success("Wakeword service initialized");
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }

    private void initializeWakewordService(String apiKey, String wakewordPath, String serverUrl) {
        Intent intent = new Intent(this, EVAAccessibilityService.class);
        intent.putExtra("apiKey", apiKey);
        intent.putExtra("wakewordPath", wakewordPath);
        intent.putExtra("serverUrl", serverUrl);
        startService(intent);
    }
}
