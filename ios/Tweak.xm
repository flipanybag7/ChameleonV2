#import <Foundation/Foundation.h>

// Minimal, non-evasive runtime companion. The full profile adapter is kept
// separate from this package so it can be tested per-app and fail closed.
// This hook only exposes a diagnostic notification and does not alter device
// identity, jailbreak checks, or security decisions made by other apps.
%ctor {
    @autoreleasepool {
        NSDictionary *info = @{
            @"component": @"ProfileRuntime",
            @"version": @"0.1.0",
            @"capabilities": @[@"profile-diagnostics", @"rootless-package"]
        };
        [[NSUserDefaults standardUserDefaults] setObject:info forKey:@"ProfileRuntime.LastStart"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
