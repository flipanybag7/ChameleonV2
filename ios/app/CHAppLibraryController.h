#import <UIKit/UIKit.h>
@class CHProfileStore;

@interface CHAppLibraryController : UITableViewController
- (instancetype)initWithStore:(CHProfileStore *)store;
@end

@interface CHProfileDetailController : UITableViewController
- (instancetype)initWithStore:(CHProfileStore *)store application:(NSDictionary *)application profileID:(NSString *)profileID;
@end
