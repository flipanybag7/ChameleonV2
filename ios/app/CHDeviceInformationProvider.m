#import "CHDeviceInformationProvider.h"
#import <dlfcn.h>
#import <dispatch/dispatch.h>

typedef CFTypeRef (*CHMGCopyAnswerFunction)(CFStringRef key);

static CHMGCopyAnswerFunction CHLoadMGCopyAnswer(void) {
    static CHMGCopyAnswerFunction function;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        function = (CHMGCopyAnswerFunction)dlsym(RTLD_DEFAULT, "MGCopyAnswer");
        if (function) return;
        void *handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY | RTLD_LOCAL);
        if (handle) function = (CHMGCopyAnswerFunction)dlsym(handle, "MGCopyAnswer");
    });
    return function;
}

static NSString *CHCopyAnswerForKeys(NSArray<NSString *> *keys) {
    CHMGCopyAnswerFunction function = CHLoadMGCopyAnswer();
    if (!function) return nil;
    for (NSString *key in keys) {
        CFTypeRef rawValue = function((__bridge CFStringRef)key);
        if (!rawValue) continue;
        id value = CFBridgingRelease(rawValue);
        NSString *text = [value isKindOfClass:NSString.class] ? value : [value description];
        if (text.length) return text;
    }
    return nil;
}

@implementation CHDeviceInformationProvider

+ (NSDictionary<NSString *, NSString *> *)deviceIdentifiers {
    NSString *unavailable = @"Unavailable";
    return @{
        @"serial": CHCopyAnswerForKeys(@[@"SerialNumber", @"kMGSerialNumber"]) ?: unavailable,
        @"imei": CHCopyAnswerForKeys(@[@"InternationalMobileEquipmentIdentity", @"InternationalMobileEquipmentIdentity2"]) ?: unavailable,
        @"meid": CHCopyAnswerForKeys(@[@"MobileEquipmentIdentifier"]) ?: unavailable,
        @"wifiMAC": CHCopyAnswerForKeys(@[@"WiFiAddress"]) ?: unavailable
    };
}

@end
