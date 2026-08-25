#import <UIKit/UIKit.h>
@class CHProfileStore;

@interface CHMapController : UIViewController
@property(nonatomic, strong) CHProfileStore *store;
@property(nonatomic) NSUInteger profileIndex;
@end
