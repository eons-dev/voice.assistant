#include "eons_voice_assistant.h"

int main(int argc, char** argv) {
  g_autoptr(EVA) app = eons_voice_assistant_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
