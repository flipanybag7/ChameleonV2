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
        if (!_data[@"schema"]) _data[@"schema"] = @2;
        NSMutableArray *migratedProfiles = [_data[@"profiles"] mutableCopy] ?: [NSMutableArray array];
        for (NSUInteger i = 0; i < migratedProfiles.count; i++) {
            NSMutableDictionary *profile = [migratedProfiles[i] mutableCopy];
            if (![profile[@"containers"] isKindOfClass:NSArray.class]) {
                NSString *containerID = profile[@"id"] ?: NSUUID.UUID.UUIDString.lowercaseString;
                profile[@"containers"] = [NSMutableArray arrayWithObject:@{@"id": containerID, @"name": @"Default", @"createdAt": @([[NSDate date] timeIntervalSince1970])}];
            }
            if (!profile[@"activeContainer"]) profile[@"activeContainer"] = [profile[@"containers"] firstObject][@"id"];
            migratedProfiles[i] = profile;
        }
        _data[@"profiles"] = migratedProfiles;
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
    NSString *profileID = NSUUID.UUID.UUIDString.lowercaseString;
    [profiles addObject:[@{@"id": profileID, @"name": name, @"apps": [NSMutableArray array], @"proxy": [NSMutableDictionary dictionary], @"location": [NSMutableDictionary dictionary], @"metadata": [NSMutableDictionary dictionary], @"containerOptions": [NSMutableDictionary dictionary], @"containers": [NSMutableArray arrayWithObject:@{@"id": profileID, @"name": @"Default", @"createdAt": @([[NSDate date] timeIntervalSince1970])}], @"activeContainer": profileID} mutableCopy]];
    self.data[@"profiles"] = profiles; [self save];
}
- (void)renameProfileAtIndex:(NSUInteger)index name:(NSString *)name {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count || !name.length) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; profile[@"name"] = name; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)setMetadataValue:(NSString *)value forKey:(NSString *)key profileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count || !key.length) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; NSMutableDictionary *metadata = [profile[@"metadata"] mutableCopy] ?: [NSMutableDictionary dictionary]; metadata[key] = value ?: @""; profile[@"metadata"] = metadata; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
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
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; BOOL enabled = [profile[@"proxy"][@"enabled"] boolValue]; profile[@"proxy"] = @{@"host": host ?: @"", @"port": @(port), @"username": @"", @"password": @"", @"enabled": @(enabled)}; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)setProxyEnabled:(BOOL)enabled forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; NSMutableDictionary *proxy = [profile[@"proxy"] mutableCopy] ?: [NSMutableDictionary dictionary]; proxy[@"enabled"] = @(enabled); profile[@"proxy"] = proxy; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)setProxyHost:(NSString *)host port:(NSInteger)port username:(NSString *)username password:(NSString *)password forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; BOOL enabled = [profile[@"proxy"][@"enabled"] boolValue]; profile[@"proxy"] = @{@"host": host ?: @"", @"port": @(port), @"username": username ?: @"", @"password": password ?: @"", @"enabled": @(enabled)}; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)setLatitude:(double)latitude longitude:(double)longitude label:(NSString *)label forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; BOOL enabled = [profile[@"location"][@"enabled"] boolValue]; profile[@"location"] = @{@"latitude": @(latitude), @"longitude": @(longitude), @"label": label ?: @"", @"enabled": @(enabled)}; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)setLocationEnabled:(BOOL)enabled forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; NSMutableDictionary *location = [profile[@"location"] mutableCopy] ?: [NSMutableDictionary dictionary]; location[@"enabled"] = @(enabled); profile[@"location"] = location; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (NSArray<NSDictionary *> *)containersForProfileAtIndex:(NSUInteger)index {
    if (index >= self.profiles.count) return @[];
    NSArray *containers = self.profiles[index][@"containers"];
    return [containers isKindOfClass:NSArray.class] ? containers : @[];
}
- (NSString *)activeContainerIDForProfileAtIndex:(NSUInteger)index {
    if (index >= self.profiles.count) return @"";
    return self.profiles[index][@"activeContainer"] ?: [self containersForProfileAtIndex:index].firstObject[@"id"] ?: @"";
}
- (void)createContainerNamed:(NSString *)name forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count || !name.length) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; NSMutableArray *containers = [[self containersForProfileAtIndex:index] mutableCopy];
    NSString *containerID = NSUUID.UUID.UUIDString.lowercaseString; [containers addObject:@{@"id": containerID, @"name": name, @"createdAt": @([[NSDate date] timeIntervalSince1970])}]; profile[@"containers"] = containers; profile[@"activeContainer"] = containerID; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)activateContainerID:(NSString *)containerID forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count || !containerID.length) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; BOOL exists = NO; for (NSDictionary *container in [self containersForProfileAtIndex:index]) if ([container[@"id"] isEqual:containerID]) { exists = YES; break; } if (!exists) return; profile[@"activeContainer"] = containerID; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)deleteContainerID:(NSString *)containerID forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count || !containerID.length) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; NSMutableArray *containers = [[self containersForProfileAtIndex:index] mutableCopy]; if (containers.count <= 1) return; NSUInteger removeIndex = [containers indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) { return [item[@"id"] isEqual:containerID]; }]; if (removeIndex == NSNotFound) return; [containers removeObjectAtIndex:removeIndex]; profile[@"containers"] = containers; if ([profile[@"activeContainer"] isEqual:containerID]) profile[@"activeContainer"] = containers.firstObject[@"id"]; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (void)setContainerOption:(BOOL)enabled key:(NSString *)key forProfileAtIndex:(NSUInteger)index {
    NSMutableArray *profiles = [self mutableProfiles]; if (index >= profiles.count || !key.length) return;
    NSMutableDictionary *profile = [profiles[index] mutableCopy]; NSMutableDictionary *options = [profile[@"containerOptions"] mutableCopy] ?: [NSMutableDictionary dictionary]; options[key] = @(enabled); profile[@"containerOptions"] = options; profiles[index] = profile; self.data[@"profiles"] = profiles; [self save];
}
- (NSURL *)exportBackup {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ChameleonBackup.json"];
    NSData *json = [NSJSONSerialization dataWithJSONObject:self.data options:NSJSONWritingPrettyPrinted error:nil]; [json writeToFile:path atomically:YES]; return [NSURL fileURLWithPath:path];
}
- (BOOL)importBackupFromURL:(NSURL *)url error:(NSError **)error {
    BOOL scoped = [url startAccessingSecurityScopedResource];
    NSData *json = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (!json) { if (scoped) [url stopAccessingSecurityScopedResource]; return NO; }
    NSDictionary *incoming = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:error];
    if (scoped) [url stopAccessingSecurityScopedResource];
    if (![incoming isKindOfClass:NSDictionary.class] || ![incoming[@"profiles"] isKindOfClass:NSArray.class]) {
        if (error) *error = [NSError errorWithDomain:@"ChameleonBackup" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Backup does not contain a valid profiles array."}];
        return NO;
    }
    self.data = [incoming mutableCopy]; if (!self.data[@"schema"]) self.data[@"schema"] = @2; [self save]; return YES;
}
@end
