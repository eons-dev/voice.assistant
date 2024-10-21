package com.eons_voice_assistant;

import android.accessibilityservice.AccessibilityService;
import android.view.accessibility.AccessibilityEvent;

public class EVAAccessibilityService extends AccessibilityService {

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // This is where the wakeword detection and audio recording logic will go.
    }

    @Override
    public void onInterrupt() {
        // This is called when the service is interrupted.
    }
}
