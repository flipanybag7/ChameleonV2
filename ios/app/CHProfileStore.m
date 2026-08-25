#import "CHProfileStore.h"
#import <CoreFoundation/CoreFoundation.h>

static NSString *const CHStorePath = @"/var/mobile/Library/Preferences/com.flipanybag7.chameleon.plist";

@interface CHProfileStore ()
@property(nonatomic, strong) NSMutableDictionary *data;
@end

@implementation CHProfileStore
- (instancetype)init {
    if ((self = [super init])) {
        _data = [NSMutableDictionary dictionaryWithContentsOfFile:CHStorePath] ?: [NSMutableDictionary dictionary];
        if (!_data[@"profiles"]) _data[@"profiles"] = [NSMutableArray array];
        if (!_data[@"schema"]) _data[@"schema"] = @1;
        [self save];
    }
    return self;
}
- (NSArray *)profiles { return self.data[@"profiles"] ?: @[]; }
- (NSString *)activeProfileID { return self.data[@"activeProfile"] ?: @""; }
- (NSDictionary *)runtime { return self.data[@"runtime"] ?: @{}; }
- (NSDictionary *)activeProfile {
    for (NSDictionary *profile in self.profiles) if ([profile[@"id"] isEqual:self.activeProfileID]) return profile;
    return nil;
}
- (NSMutableArray *)mutableProfiles { return [self.profiles mutableCopy]; }
- (void)save {
    [self.data writeToFile:CHStorePath atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.flipanybag7.chameleon.profileChanged"), NULL, NULL, YES);
}
- (void)addProfileNamed:(NSString *)name {
    NSMutableArray *profiles = [self mutableProfiles];
    [profiles addObject:[@{@"id": NSUUID.UUID.UUIDString.lowercaseString, @"name": name, @"apps": [NSMutableArray array], @"proxy": [NSMutableDictionary dictionary], @"location": [NSMutableDictionary dictionary]} mutableCopy]];
    self.data[@"profiles"] = profiles; [self save];
}
- (void)deleteProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count) return;
    NSString *identifier = profiles[index][@"id"]; [profiles removeObjectAtIndex:index]; self.data[@"profiles"] = profiles;
    if ([identifier isEqual:self.activeProfileID]) [self.data removeObjectForKey:@"activeProfile"];
    [self save];
}
- (void)activateProfileAtIndex:(NSUInteger)index {
    if (index >= self.profiles.count) return; self.data[@"activeProfile"] = self.profiles[index][@"id"]; [self save];
}
- (void)addBundleID:(NSString *)bundleID toProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; NSMutableArray *apps = [profile[@"apps"] mutableCopy] ?: [NSMutableArray array];
    if (![apps containsObject:bundleID]) [apps addObject:bundleID]; profile[@"apps"] = apps; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)setProxyHost:(NSString *)host port:(NSInteger)port forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; BOOL enabled = [profile[@"proxy"][@"enabled"] boolValue]; profile[@"proxy"] = @{@"host": host ?: @"", @"port": @(port), @"enabled": @(enabled)}; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)setProxyEnabled:(BOOL)enabled forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; NSMutableDictionary *proxy = [profile[@"proxy"] mutableCopy] ?: [NSMutableDictionary dictionary]; proxy[@"enabled"] = @(enabled); profile[@"proxy"] = proxy; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)setLatitude:(double)latitude longitude:(double)longitude label:(NSString *)label forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; BOOL enabled = [profile[@"location"][@"enabled"] boolValue]; profile[@"location"] = @{@"latitude": @(latitude), @"longitude": @(longitude), @"label": label ?: @"", @"enabled": @(enabled)}; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)setLocationEnabled:(BOOL)enabled forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; NSMutableDictionary *location = [profile[@"location"] mutableCopy] ?: [NSMutableDictionary dictionary]; location[@"enabled"] = @(enabled); profile[@"location"] = location; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (NSURL *)exportBackup {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ChameleonBackup.json"];
    NSData *json = [NSJSONSerialization dataWithJSONObject:self.data options:NSJSONWritingPrettyPrinted error:nil]; [json writeToFile:path atomically:YES]; return [NSURL fileURLWithPath:path];
}
@end
