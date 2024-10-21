import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "picovoice_wakeword_channel";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("startWakewordService")) {
                        // Start the wakeword service
                        result.success("Service started");
                    } else if (call.method.equals("stopWakewordService")) {
                        // Stop the service
                        result.success("Service stopped");
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }
}
