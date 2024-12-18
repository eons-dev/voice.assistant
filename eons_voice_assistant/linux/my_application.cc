#include "eons_voice_assistant.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _EVA {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(EVA, eons_voice_assistant, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void eons_voice_assistant_activate(GApplication* application) {
  EVA* self = EONS_VOICE_ASSISTANT(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "eons_voice_assistant");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "eons_voice_assistant");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean eons_voice_assistant_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  EVA* self = EONS_VOICE_ASSISTANT(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void eons_voice_assistant_startup(GApplication* application) {
  //EVA* self = EONS_VOICE_ASSISTANT(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(eons_voice_assistant_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void eons_voice_assistant_shutdown(GApplication* application) {
  //EVA* self = EONS_VOICE_ASSISTANT(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(eons_voice_assistant_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void eons_voice_assistant_dispose(GObject* object) {
  EVA* self = EONS_VOICE_ASSISTANT(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(eons_voice_assistant_parent_class)->dispose(object);
}

static void eons_voice_assistant_class_init(EVAClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = eons_voice_assistant_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = eons_voice_assistant_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = eons_voice_assistant_startup;
  G_APPLICATION_CLASS(klass)->shutdown = eons_voice_assistant_shutdown;
  G_OBJECT_CLASS(klass)->dispose = eons_voice_assistant_dispose;
}

static void eons_voice_assistant_init(EVA* self) {}

EVA* eons_voice_assistant_new() {
  return EONS_VOICE_ASSISTANT(g_object_new(eons_voice_assistant_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
