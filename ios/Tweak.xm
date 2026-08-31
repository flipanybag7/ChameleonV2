#import <Foundation/Foundation.h>

static NSString *const CHStorePath = @"/var/mobile/Library/Preferences/com.flipanybag7.chameleon.plist";

static void CHRecordRuntimeState(void) {
    NSMutableDictionary *store = [NSMutableDictionary dictionaryWithContentsOfFile:CHStorePath] ?: [NSMutableDictionary dictionary];
    NSString *activeProfileID = store[@"activeProfile"] ?: @"";
    NSString *activeContainerID = @"";
    for (NSDictionary *profile in store[@"profiles"]) {
        if ([profile[@"id"] isEqual:activeProfileID]) {
            activeContainerID = profile[@"activeContainer"] ?: [profile[@"containers"] firstObject][@"id"] ?: @"";
            break;
        }
    }
    store[@"runtime"] = @{
        @"component": @"ProfileRuntime",
        @"version": @"0.6.0",
        @"lastStart": @([[NSDate date] timeIntervalSince1970]),
        @"activeProfile": activeProfileID,
        @"activeContainer": activeContainerID,
        @"containerMode": @"app-scoped-registry"
    };
    [store writeToFile:CHStorePath atomically:YES];
}

static void CHProfileChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    CHRecordRuntimeState();
}

%ctor {
    @autoreleasepool {
        NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
        if ([bundleID isEqualToString:@"com.apple.springboard"] || [bundleID isEqualToString:@"com.flipanybag7.chameleon.app"]) {
            CHRecordRuntimeState();
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CHProfileChanged, CFSTR("com.flipanybag7.chameleon.profileChanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        }
    }
}
