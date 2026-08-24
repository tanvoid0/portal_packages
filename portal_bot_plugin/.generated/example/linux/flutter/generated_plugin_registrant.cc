//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <portal_bot/portal_bot_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) portal_bot_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PortalBotPlugin");
  portal_bot_plugin_register_with_registrar(portal_bot_registrar);
}
