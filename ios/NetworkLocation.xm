#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

static NSString *const CHRuntimeStorePath = @"/var/mobile/Library/Preferences/com.flipanybag7.chameleon.plist";
static NSDictionary *CHRuntimeProxy;
static NSDictionary *CHRuntimeLocation;

static NSDictionary *CHRuntimeSelectedProfile(void) {
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    NSString *bundlePath = NSBundle.mainBundle.bundlePath;
    if (!bundleID.length || ![bundlePath containsString:@"/var/containers/Bundle/Application/"]) return nil;
    NSDictionary *store = [NSDictionary dictionaryWithContentsOfFile:CHRuntimeStorePath];
    NSString *activeID = store[@"activeProfile"];
    for (NSDictionary *profile in store[@"profiles"]) {
        if ([profile[@"id"] isEqual:activeID] && [profile[@"apps"] containsObject:bundleID]) return profile;
    }
    return nil;
}

static NSURLSessionConfiguration *CHApplyProxy(NSURLSessionConfiguration *configuration) {
    NSString *host = CHRuntimeProxy[@"host"];
    NSNumber *port = CHRuntimeProxy[@"port"];
    NSString *type = [CHRuntimeProxy[@"type"] lowercaseString] ?: @"http";
    if (!configuration || !host.length || port.integerValue <= 0) return configuration;
    NSMutableDictionary *settings = [configuration.connectionProxyDictionary mutableCopy] ?: [NSMutableDictionary dictionary];
    if ([type isEqualToString:@"socks5"]) {
        settings[@"SOCKSEnable"] = @YES; settings[@"SOCKSProxy"] = host; settings[@"SOCKSPort"] = port;
    } else {
        settings[@"HTTPEnable"] = @YES; settings[@"HTTPProxy"] = host; settings[@"HTTPPort"] = port;
        settings[@"HTTPSEnable"] = @YES; settings[@"HTTPSProxy"] = host; settings[@"HTTPSPort"] = port;
    }
    NSString *username = CHRuntimeProxy[@"username"], *password = CHRuntimeProxy[@"password"];
    if (username.length) settings[@"ProxyUsername"] = username;
    if (password.length) settings[@"ProxyPassword"] = password;
    configuration.connectionProxyDictionary = settings;
    return configuration;
}

%group CHProxyRuntimeHooks
%hook NSURLSessionConfiguration
+ (NSURLSessionConfiguration *)defaultSessionConfiguration {
    NSURLSessionConfiguration *configuration = %orig;
    return CHApplyProxy(configuration);
}
+ (NSURLSessionConfiguration *)ephemeralSessionConfiguration {
    NSURLSessionConfiguration *configuration = %orig;
    return CHApplyProxy(configuration);
}
+ (NSURLSessionConfiguration *)backgroundSessionConfigurationWithIdentifier:(NSString *)identifier {
    NSURLSessionConfiguration *configuration = %orig;
    return CHApplyProxy(configuration);
}
%end
%end

%group CHLocationRuntimeHooks
%hook CLLocation
- (CLLocationCoordinate2D)coordinate {
    double latitude = [CHRuntimeLocation[@"latitude"] doubleValue];
    double longitude = [CHRuntimeLocation[@"longitude"] doubleValue];
    if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180) return CLLocationCoordinate2DMake(latitude, longitude);
    return %orig;
}
- (CLLocationAccuracy)horizontalAccuracy {
    NSNumber *accuracy = CHRuntimeLocation[@"horizontalAccuracy"];
    if (accuracy.doubleValue > 0) return accuracy.doubleValue;
    return 5.0;
}
- (CLLocationAccuracy)verticalAccuracy {
    NSNumber *accuracy = CHRuntimeLocation[@"verticalAccuracy"];
    if (accuracy.doubleValue > 0) return accuracy.doubleValue;
    return 8.0;
}
%end
%end

%ctor {
    @autoreleasepool {
        NSDictionary *profile = CHRuntimeSelectedProfile();
        CHRuntimeProxy = [profile[@"proxy"] copy];
        CHRuntimeLocation = [profile[@"location"] copy];
        if (profile && [CHRuntimeProxy[@"enabled"] boolValue] && [CHRuntimeProxy[@"host"] length] && [CHRuntimeProxy[@"port"] integerValue] > 0) %init(CHProxyRuntimeHooks);
        if (profile && [CHRuntimeLocation[@"enabled"] boolValue]) %init(CHLocationRuntimeHooks);
    }
}
