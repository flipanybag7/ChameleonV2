#import <Foundation/Foundation.h>

@interface CHProfileStore : NSObject
@property(nonatomic, readonly) NSArray<NSDictionary *> *profiles;
@property(nonatomic, readonly) NSString *activeProfileID;
@property(nonatomic, readonly) NSDictionary *runtime;
- (NSDictionary *)activeProfile;
- (void)addProfileNamed:(NSString *)name;
- (void)renameProfileAtIndex:(NSUInteger)index name:(NSString *)name;
- (void)setMetadataValue:(NSString *)value forKey:(NSString *)key profileAtIndex:(NSUInteger)index;
- (void)setDeviceValue:(id)value forKey:(NSString *)key profileAtIndex:(NSUInteger)index;
- (void)setDeviceValues:(NSDictionary *)values profileAtIndex:(NSUInteger)index;
- (void)setDeviceEnabled:(BOOL)enabled profileAtIndex:(NSUInteger)index;
- (void)deleteProfileAtIndex:(NSUInteger)index;
- (void)activateProfileAtIndex:(NSUInteger)index;
- (void)addBundleID:(NSString *)bundleID toProfileAtIndex:(NSUInteger)index;
- (void)setProxyHost:(NSString *)host port:(NSInteger)port forProfileAtIndex:(NSUInteger)index;
- (void)setProxyHost:(NSString *)host port:(NSInteger)port username:(NSString *)username password:(NSString *)password forProfileAtIndex:(NSUInteger)index;
- (void)setProxyEnabled:(BOOL)enabled forProfileAtIndex:(NSUInteger)index;
- (void)setLatitude:(double)latitude longitude:(double)longitude label:(NSString *)label forProfileAtIndex:(NSUInteger)index;
- (void)setLocationEnabled:(BOOL)enabled forProfileAtIndex:(NSUInteger)index;
- (NSArray<NSDictionary *> *)containersForProfileAtIndex:(NSUInteger)index;
- (NSString *)activeContainerIDForProfileAtIndex:(NSUInteger)index;
- (void)createContainerNamed:(NSString *)name forProfileAtIndex:(NSUInteger)index;
- (void)activateContainerID:(NSString *)containerID forProfileAtIndex:(NSUInteger)index;
- (void)deleteContainerID:(NSString *)containerID forProfileAtIndex:(NSUInteger)index;
- (void)setContainerOption:(BOOL)enabled key:(NSString *)key forProfileAtIndex:(NSUInteger)index;
- (NSURL *)exportBackup;
- (BOOL)importBackupFromURL:(NSURL *)url error:(NSError **)error;
@end
