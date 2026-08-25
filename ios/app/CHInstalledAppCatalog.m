#import "CHInstalledAppCatalog.h"
#import <UIKit/UIKit.h>

@interface UIImage (CHApplicationIcon)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(NSInteger)format scale:(CGFloat)scale;
@end

@implementation CHInstalledAppCatalog
+ (NSArray<NSDictionary *> *)thirdPartyApplications {
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    id workspace = [workspaceClass respondsToSelector:@selector(defaultWorkspace)] ? [workspaceClass performSelector:@selector(defaultWorkspace)] : nil;
    NSArray *installed = [workspace respondsToSelector:@selector(allInstalledApplications)] ? [workspace performSelector:@selector(allInstalledApplications)] : @[];
    NSMutableArray *result = [NSMutableArray array];
    for (id app in installed) {
        @try {
            NSString *bundleID = [app valueForKey:@"applicationIdentifier"];
            NSString *type = [app valueForKey:@"applicationType"];
            NSURL *bundleURL = [app valueForKey:@"bundleURL"];
            NSString *path = bundleURL.path ?: @"";
            BOOL userApplication = [type caseInsensitiveCompare:@"User"] == NSOrderedSame;
            BOOL userContainer = [path containsString:@"/var/containers/Bundle/Application/"] || [path containsString:@"/private/var/containers/Bundle/Application/"];
            if (!bundleID.length || !userApplication || !userContainer) continue;
            NSString *name = [app valueForKey:@"localizedName"] ?: bundleID;
            UIImage *icon = nil;
            if ([UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:scale:)]) icon = [UIImage _applicationIconImageForBundleIdentifier:bundleID format:2 scale:UIScreen.mainScreen.scale];
            NSMutableDictionary *item = [@{@"name": name, @"bundleID": bundleID, @"path": path} mutableCopy];
            if (icon) item[@"icon"] = icon;
            [result addObject:item];
        } @catch (__unused NSException *exception) {}
    }
    [result sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) { return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]]; }];
    return result;
}
@end
