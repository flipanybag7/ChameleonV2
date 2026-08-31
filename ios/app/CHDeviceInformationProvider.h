#import <Foundation/Foundation.h>

@interface CHDeviceInformationProvider : NSObject
+ (NSDictionary<NSString *, NSString *> *)deviceIdentifiers;
@end
