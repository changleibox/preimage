//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <preimage/preimage_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) preimage_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PreimagePlugin");
  preimage_plugin_register_with_registrar(preimage_registrar);
}
