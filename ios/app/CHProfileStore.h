#import <Foundation/Foundation.h>

@interface CHProfileStore : NSObject
@property(nonatomic, readonly) NSArray<NSDictionary *> *profiles;
@property(nonatomic, readonly) NSString *activeProfileID;
@property(nonatomic, readonly) NSDictionary *runtime;
- (NSDictionary *)activeProfile;
- (void)addProfileNamed:(NSString *)name;
- (void)deleteProfileAtIndex:(NSUInteger)index;
- (void)activateProfileAtIndex:(NSUInteger)index;
- (void)addBundleID:(NSString *)bundleID toProfileAtIndex:(NSUInteger)index;
- (void)setProxyHost:(NSString *)host port:(NSInteger)port forProfileAtIndex:(NSUInteger)index;
- (void)setProxyEnabled:(BOOL)enabled forProfileAtIndex:(NSUInteger)index;
- (void)setLatitude:(double)latitude longitude:(double)longitude label:(NSString *)label forProfileAtIndex:(NSUInteger)index;
- (void)setLocationEnabled:(BOOL)enabled forProfileAtIndex:(NSUInteger)index;
- (NSURL *)exportBackup;
@end
