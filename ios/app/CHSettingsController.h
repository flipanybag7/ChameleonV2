#import <UIKit/UIKit.h>

@class CHProfileStore;

@interface CHSettingsController : UITableViewController
- (instancetype)initWithStore:(CHProfileStore *)store;
@end
