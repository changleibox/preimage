#import "PreimagePlugin.h"
#if __has_include(<preimage/preimage-Swift.h>)
#import <preimage/preimage-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "preimage-Swift.h"
#endif

@implementation PreimagePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPreimagePlugin registerWithRegistrar:registrar];
}
@end
