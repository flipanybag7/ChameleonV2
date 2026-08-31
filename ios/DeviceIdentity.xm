#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>
#import <substrate.h>

#include <dlfcn.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <sys/sysctl.h>

static NSString *const CHIdentityStorePath = @"/var/mobile/Library/Preferences/com.flipanybag7.chameleon.plist";
static NSDictionary *CHIdentityDevice;
static NSString *CHIdentityBundleID;
static BOOL CHIdentityEnabled;

typedef int (*CHSysctlByNameFn)(const char *, void *, size_t *, const void *, size_t);
static CHSysctlByNameFn CHOriginalSysctlByName;

static NSDictionary *CHSelectedProfile(void) {
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    NSString *bundlePath = NSBundle.mainBundle.bundlePath;
    if (bundleID.length == 0 || ![bundlePath containsString:@"/var/containers/Bundle/Application/"]) return nil;
    NSDictionary *store = [NSDictionary dictionaryWithContentsOfFile:CHIdentityStorePath];
    NSString *activeID = store[@"activeProfile"];
    if (activeID.length == 0) return nil;
    for (NSDictionary *profile in store[@"profiles"]) {
        if ([profile[@"id"] isEqual:activeID] && [profile[@"apps"] containsObject:bundleID]) return profile;
    }
    return nil;
}

static NSString *CHIdentityString(NSString *key) {
    id value = CHIdentityDevice[key];
    if ([value isKindOfClass:NSString.class]) return [value length] ? value : nil;
    return value == nil ? nil : [value description];
}

static double CHIdentityDouble(NSString *key) {
    return [CHIdentityDevice[key] doubleValue];
}

static NSString *CHConfiguredLocaleIdentifier(void) {
    NSString *identifier = CHIdentityString(@"localeIdentifier");
    NSString *region = CHIdentityString(@"regionCode");
    if (!identifier.length || !region.length) return identifier;
    NSMutableDictionary *components = [[NSLocale componentsFromLocaleIdentifier:identifier] mutableCopy];
    components[NSLocaleCountryCode] = region.uppercaseString;
    return [NSLocale localeIdentifierFromComponents:components];
}

static NSUUID *CHSyntheticIDFV(void) {
    NSString *seed = CHIdentityString(@"idfvSeed");
    if (!seed.length || !CHIdentityBundleID.length) return nil;
    NSData *data = [[NSString stringWithFormat:@"%@|%@", seed, CHIdentityBundleID] dataUsingEncoding:NSUTF8StringEncoding];
    const uint8_t *bytes = data.bytes;
    uint64_t first = UINT64_C(1469598103934665603), second = UINT64_C(1099511628211);
    for (NSUInteger index = 0; index < data.length; index++) {
        first ^= bytes[index]; first *= UINT64_C(1099511628211);
        second ^= (uint8_t)(bytes[index] + index); second *= UINT64_C(1469598103934665603);
    }
    uint8_t uuidBytes[16];
    memcpy(uuidBytes, &first, 8); memcpy(uuidBytes + 8, &second, 8);
    uuidBytes[6] = (uuidBytes[6] & 0x0f) | 0x40;
    uuidBytes[8] = (uuidBytes[8] & 0x3f) | 0x80;
    return [[NSUUID alloc] initWithUUIDBytes:uuidBytes];
}

static BOOL CHParseVersion(NSString *version, NSOperatingSystemVersion *parsed) {
    if (!version.length || parsed == NULL) return NO;
    NSArray<NSString *> *parts = [version componentsSeparatedByString:@"."];
    if (!parts.count) return NO;
    parsed->majorVersion = [parts[0] integerValue];
    parsed->minorVersion = parts.count > 1 ? [parts[1] integerValue] : 0;
    parsed->patchVersion = parts.count > 2 ? [parts[2] integerValue] : 0;
    return parsed->majorVersion > 0;
}

static int CHWriteSysctlString(NSString *value, void *oldValue, size_t *oldLength) {
    if (oldLength == NULL) { errno = EFAULT; return -1; }
    const char *string = value.UTF8String;
    size_t required = strlen(string) + 1;
    if (oldValue == NULL) { *oldLength = required; return 0; }
    if (*oldLength < required) { *oldLength = required; errno = ENOMEM; return -1; }
    memcpy(oldValue, string, required); *oldLength = required; return 0;
}

static int CHWriteSysctlUInt64(uint64_t value, void *oldValue, size_t *oldLength) {
    if (oldLength == NULL) { errno = EFAULT; return -1; }
    if (oldValue == NULL) { *oldLength = sizeof(value); return 0; }
    if (*oldLength < sizeof(value)) { *oldLength = sizeof(value); errno = ENOMEM; return -1; }
    memcpy(oldValue, &value, sizeof(value)); *oldLength = sizeof(value); return 0;
}

static int CHSysctlByName(const char *name, void *oldValue, size_t *oldLength, const void *newValue, size_t newLength) {
    if (CHIdentityEnabled && name != NULL && newValue == NULL) {
        if (strcmp(name, "hw.machine") == 0) {
            NSString *value = CHIdentityString(@"machine"); if (value.length) return CHWriteSysctlString(value, oldValue, oldLength);
        } else if (strcmp(name, "hw.model") == 0) {
            NSString *value = CHIdentityString(@"hardwareModel"); if (value.length) return CHWriteSysctlString(value, oldValue, oldLength);
        } else if (strcmp(name, "hw.memsize") == 0) {
            double gigabytes = CHIdentityDouble(@"physicalMemoryGB");
            if (gigabytes > 0) return CHWriteSysctlUInt64((uint64_t)(gigabytes * 1073741824.0), oldValue, oldLength);
        }
    }
    return CHOriginalSysctlByName(name, oldValue, oldLength, newValue, newLength);
}

%hook UIDevice
- (NSString *)model { NSString *value = CHIdentityString(@"deviceModel"); return CHIdentityEnabled && value.length ? value : %orig; }
- (NSString *)localizedModel { NSString *value = CHIdentityString(@"marketingName"); return CHIdentityEnabled && value.length ? value : %orig; }
- (NSString *)systemVersion { NSString *value = CHIdentityString(@"systemVersion"); return CHIdentityEnabled && value.length ? value : %orig; }
- (NSUUID *)identifierForVendor { NSUUID *value = CHIdentityEnabled ? CHSyntheticIDFV() : nil; return value ?: %orig; }
%end

%hook NSProcessInfo
- (unsigned long long)physicalMemory { double value = CHIdentityDouble(@"physicalMemoryGB"); return CHIdentityEnabled && value > 0 ? (unsigned long long)(value * 1073741824.0) : %orig; }
- (NSString *)operatingSystemVersionString { NSString *value = CHIdentityString(@"systemVersion"); return CHIdentityEnabled && value.length ? [NSString stringWithFormat:@"Version %@", value] : %orig; }
- (NSOperatingSystemVersion)operatingSystemVersion { NSOperatingSystemVersion value; return CHIdentityEnabled && CHParseVersion(CHIdentityString(@"systemVersion"), &value) ? value : %orig; }
- (BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)required { NSOperatingSystemVersion value; if (!CHIdentityEnabled || !CHParseVersion(CHIdentityString(@"systemVersion"), &value)) return %orig; if (value.majorVersion != required.majorVersion) return value.majorVersion > required.majorVersion; if (value.minorVersion != required.minorVersion) return value.minorVersion > required.minorVersion; return value.patchVersion >= required.patchVersion; }
%end

%hook UIScreen
- (CGRect)nativeBounds { double width = CHIdentityDouble(@"screenWidth"), height = CHIdentityDouble(@"screenHeight"); return CHIdentityEnabled && self == UIScreen.mainScreen && width > 0 && height > 0 ? CGRectMake(0, 0, width, height) : %orig; }
- (CGFloat)nativeScale { double value = CHIdentityDouble(@"screenScale"); return CHIdentityEnabled && self == UIScreen.mainScreen && value > 0 ? value : %orig; }
- (CGRect)bounds { double width = CHIdentityDouble(@"screenWidth"), height = CHIdentityDouble(@"screenHeight"), scale = CHIdentityDouble(@"screenScale"); return CHIdentityEnabled && self == UIScreen.mainScreen && width > 0 && height > 0 && scale > 0 ? CGRectMake(0, 0, width / scale, height / scale) : %orig; }
- (CGFloat)scale { double value = CHIdentityDouble(@"screenScale"); return CHIdentityEnabled && self == UIScreen.mainScreen && value > 0 ? value : %orig; }
%end

%hook NSLocale
+ (NSLocale *)currentLocale { NSString *value = CHConfiguredLocaleIdentifier(); return CHIdentityEnabled && value.length ? [NSLocale localeWithLocaleIdentifier:value] : %orig; }
+ (NSLocale *)autoupdatingCurrentLocale { NSString *value = CHConfiguredLocaleIdentifier(); return CHIdentityEnabled && value.length ? [NSLocale localeWithLocaleIdentifier:value] : %orig; }
+ (NSArray<NSString *> *)preferredLanguages { NSString *identifier = CHConfiguredLocaleIdentifier(); NSString *language = identifier.length ? [NSLocale componentsFromLocaleIdentifier:identifier][NSLocaleLanguageCode] : nil; return CHIdentityEnabled && language.length ? @[language] : %orig; }
%end

%hook NSTimeZone
+ (NSTimeZone *)localTimeZone { NSString *name = CHIdentityString(@"timeZone"); NSTimeZone *value = name.length ? [NSTimeZone timeZoneWithName:name] : nil; return CHIdentityEnabled && value ? value : %orig; }
+ (NSTimeZone *)defaultTimeZone { NSString *name = CHIdentityString(@"timeZone"); NSTimeZone *value = name.length ? [NSTimeZone timeZoneWithName:name] : nil; return CHIdentityEnabled && value ? value : %orig; }
+ (NSTimeZone *)systemTimeZone { NSString *name = CHIdentityString(@"timeZone"); NSTimeZone *value = name.length ? [NSTimeZone timeZoneWithName:name] : nil; return CHIdentityEnabled && value ? value : %orig; }
%end

%hook CTCarrier
- (NSString *)carrierName { NSString *value = CHIdentityString(@"carrierName"); return CHIdentityEnabled && value.length ? value : %orig; }
- (NSString *)mobileCountryCode { NSString *value = CHIdentityString(@"mcc"); return CHIdentityEnabled && value.length ? value : %orig; }
- (NSString *)mobileNetworkCode { NSString *value = CHIdentityString(@"mnc"); return CHIdentityEnabled && value.length ? value : %orig; }
- (NSString *)isoCountryCode { NSString *value = CHIdentityString(@"isoCountryCode"); return CHIdentityEnabled && value.length ? value.lowercaseString : %orig; }
%end

%ctor {
    @autoreleasepool {
        NSDictionary *profile = CHSelectedProfile();
        CHIdentityDevice = [profile[@"device"] copy];
        CHIdentityBundleID = [NSBundle.mainBundle.bundleIdentifier copy];
        CHIdentityEnabled = profile != nil && [CHIdentityDevice[@"enabled"] boolValue];
        if (CHIdentityEnabled) {
            void *address = dlsym(RTLD_DEFAULT, "sysctlbyname");
            if (address != NULL) MSHookFunction(address, (void *)&CHSysctlByName, (void **)&CHOriginalSysctlByName);
        }
    }
}
