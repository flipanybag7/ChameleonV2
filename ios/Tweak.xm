#import <Foundation/Foundation.h>

static NSString *const CHStorePath = @"/var/mobile/Library/Preferences/com.flipanybag7.chameleon.plist";

static void CHRecordRuntimeState(void) {
    NSMutableDictionary *store = [NSMutableDictionary dictionaryWithContentsOfFile:CHStorePath] ?: [NSMutableDictionary dictionary];
    store[@"runtime"] = @{
        @"component": @"ProfileRuntime",
        @"version": @"0.5.1",
        @"lastStart": @([[NSDate date] timeIntervalSince1970]),
        @"activeProfile": store[@"activeProfile"] ?: @""
    };
    [store writeToFile:CHStorePath atomically:YES];
}

static void CHProfileChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    CHRecordRuntimeState();
}

%ctor {
    @autoreleasepool {
        CHRecordRuntimeState();
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CHProfileChanged, CFSTR("com.flipanybag7.chameleon.profileChanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}
