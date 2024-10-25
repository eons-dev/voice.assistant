#ifndef FLUTTER_EONS_VOICE_ASSISTANT_H_
#define FLUTTER_EONS_VOICE_ASSISTANT_H_

#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(EVA, eons_voice_assistant, MY, APPLICATION,
                     GtkApplication)

/**
 * eons_voice_assistant_new:
 *
 * Creates a new Flutter-based application.
 *
 * Returns: a new #EVA.
 */
EVA* eons_voice_assistant_new();

#endif  // FLUTTER_EONS_VOICE_ASSISTANT_H_
