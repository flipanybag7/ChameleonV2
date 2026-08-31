#import <Foundation/Foundation.h>
#import <substrate.h>

#include <dlfcn.h>
#include <dirent.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <sys/stat.h>
#include <unistd.h>

// The container is deliberately scoped to the app's data directory.  Bundle
// resources and system paths continue to resolve normally, which is required
// for an injected tweak to keep the host app launchable.
static NSString *const CHContainerBase = @"/var/mobile/Library/Chameleon/Containers";
static NSString *const CHStorePath = @"/var/mobile/Library/Preferences/com.flipanybag7.chameleon.plist";
static BOOL CHContainerEnabled;
static NSString *CHResolvedContainerRoot;

typedef int (*CHOpenFn)(const char *, int, ...);
typedef int (*CHOpenAtFn)(int, const char *, int, ...);
typedef int (*CHStatFn)(const char *, struct stat *);
typedef int (*CHFstatAtFn)(int, const char *, struct stat *, int);
typedef FILE *(*CHFopenFn)(const char *, const char *);
typedef FILE *(*CHFreopenFn)(const char *, const char *, FILE *);
typedef int (*CHPathIntFn)(const char *);
typedef int (*CHAccessFn)(const char *, int);
typedef int (*CHRenameFn)(const char *, const char *);
typedef int (*CHMkdirFn)(const char *, mode_t);
typedef DIR *(*CHOpendirFn)(const char *);
typedef ssize_t (*CHReadlinkFn)(const char *, char *, size_t);
typedef int (*CHChmodFn)(const char *, mode_t);

static CHOpenFn CHOriginalOpen;
static CHOpenAtFn CHOriginalOpenAt;
static CHStatFn CHOriginalStat;
static CHStatFn CHOriginalLstat;
static CHFstatAtFn CHOriginalFstatAt;
static CHFopenFn CHOriginalFopen;
static CHFreopenFn CHOriginalFreopen;
static CHPathIntFn CHOriginalUnlink;
static CHPathIntFn CHOriginalRmdir;
static CHAccessFn CHOriginalAccess;
static CHRenameFn CHOriginalRename;
static CHMkdirFn CHOriginalMkdir;
static CHOpendirFn CHOriginalOpendir;
static CHReadlinkFn CHOriginalReadlink;
static CHChmodFn CHOriginalChmod;

static BOOL CHHasPathPrefix(NSString *path, NSString *prefix) {
    return [path isEqualToString:prefix] || [path hasPrefix:[prefix stringByAppendingString:@"/"]];
}

static NSString *CHContainerRoot(void) {
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    NSDictionary *store = [NSDictionary dictionaryWithContentsOfFile:CHStorePath];
    NSString *profileID = store[@"activeProfile"];
    if (bundleID.length == 0 || profileID.length == 0) return nil;
    NSString *containerID = profileID;
    for (NSDictionary *profile in store[@"profiles"]) if ([profile[@"id"] isEqual:profileID]) { containerID = profile[@"activeContainer"] ?: [profile[@"containers"] firstObject][@"id"] ?: profileID; break; }
    return [[[[CHContainerBase stringByAppendingPathComponent:bundleID]
              stringByAppendingPathComponent:profileID]
             stringByAppendingPathComponent:containerID] stringByStandardizingPath];
}

static NSString *CHMapPath(const char *rawPath) {
    if (!CHContainerEnabled) return nil;
    if (rawPath == NULL || rawPath[0] == '\0') return nil;

    NSString *path = [NSString stringWithUTF8String:rawPath];
    NSString *home = NSHomeDirectory();
    NSString *root = CHResolvedContainerRoot;
    if (path.length == 0 || home.length == 0 || root.length == 0) return nil;

    // open/stat with a relative path are relative to the process cwd.  iOS
    // apps normally start in their sandbox, so treat those paths as sandbox
    // paths too.  Absolute paths outside the sandbox are intentionally left
    // untouched.
    if (![path hasPrefix:@"/"]) path = [home stringByAppendingPathComponent:path];
    path = path.stringByStandardizingPath;
    home = home.stringByStandardizingPath;

    if (!CHHasPathPrefix(path, home) || CHHasPathPrefix(path, root)) return nil;
    NSString *relative = [path substringFromIndex:home.length];
    return [root stringByAppendingPathComponent:relative];
}

static const char *CHMappedCString(const char *path, NSString **mapped) {
    *mapped = CHMapPath(path);
    return *mapped == nil ? path : (*mapped).fileSystemRepresentation;
}

static int CHOpen(const char *path, int flags, ...) {
    NSString *mapped = nil;
    const char *target = CHMappedCString(path, &mapped);
    if ((flags & O_CREAT) != 0) {
        va_list args;
        va_start(args, flags);
        mode_t mode = (mode_t)va_arg(args, int);
        va_end(args);
        return CHOriginalOpen(path == NULL ? path : target, flags, mode);
    }
    return CHOriginalOpen(path == NULL ? path : target, flags);
}

static int CHOpenAt(int dirfd, const char *path, int flags, ...) {
    // A relative openat() against an already-open directory cannot be safely
    // reconstructed from a pathname.  Absolute paths and AT_FDCWD are safe;
    // other dirfds retain normal kernel semantics.
    NSString *mapped = nil;
    const char *target = path;
    if (dirfd == AT_FDCWD || (path && path[0] == '/')) target = CHMappedCString(path, &mapped);

    if ((flags & O_CREAT) != 0) {
        va_list args;
        va_start(args, flags);
        mode_t mode = (mode_t)va_arg(args, int);
        va_end(args);
        return CHOriginalOpenAt(dirfd, target, flags, mode);
    }
    return CHOriginalOpenAt(dirfd, target, flags);
}

static int CHStat(const char *path, struct stat *buffer) {
    NSString *mapped = nil;
    return CHOriginalStat(CHMappedCString(path, &mapped), buffer);
}

static int CHLstat(const char *path, struct stat *buffer) {
    NSString *mapped = nil;
    return CHOriginalLstat(CHMappedCString(path, &mapped), buffer);
}

static int CHFstatAt(int dirfd, const char *path, struct stat *buffer, int flags) {
    NSString *mapped = nil;
    const char *target = (dirfd == AT_FDCWD || (path && path[0] == '/')) ? CHMappedCString(path, &mapped) : path;
    return CHOriginalFstatAt(dirfd, target, buffer, flags);
}

static FILE *CHFopen(const char *path, const char *mode) { NSString *mapped = nil; return CHOriginalFopen(CHMappedCString(path, &mapped), mode); }
static FILE *CHFreopen(const char *path, const char *mode, FILE *stream) { NSString *mapped = nil; return CHOriginalFreopen(path ? CHMappedCString(path, &mapped) : NULL, mode, stream); }
static int CHUnlink(const char *path) { NSString *mapped = nil; return CHOriginalUnlink(CHMappedCString(path, &mapped)); }
static int CHRmdir(const char *path) { NSString *mapped = nil; return CHOriginalRmdir(CHMappedCString(path, &mapped)); }
static int CHAccess(const char *path, int mode) { NSString *mapped = nil; return CHOriginalAccess(CHMappedCString(path, &mapped), mode); }
static int CHRename(const char *oldPath, const char *newPath) { NSString *oldMapped = nil, *newMapped = nil; return CHOriginalRename(CHMappedCString(oldPath, &oldMapped), CHMappedCString(newPath, &newMapped)); }
static int CHMkdir(const char *path, mode_t mode) { NSString *mapped = nil; return CHOriginalMkdir(CHMappedCString(path, &mapped), mode); }
static DIR *CHOpendir(const char *path) { NSString *mapped = nil; return CHOriginalOpendir(CHMappedCString(path, &mapped)); }
static ssize_t CHReadlink(const char *path, char *buffer, size_t size) { NSString *mapped = nil; return CHOriginalReadlink(CHMappedCString(path, &mapped), buffer, size); }
static int CHChmod(const char *path, mode_t mode) { NSString *mapped = nil; return CHOriginalChmod(CHMappedCString(path, &mapped), mode); }

static void CHInstallHook(const char *symbol, void *replacement, void **original) {
    void *address = dlsym(RTLD_DEFAULT, symbol);
    if (address != NULL) MSHookFunction(address, replacement, original);
}

static BOOL CHIsSelectedUserApp(void) {
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    NSString *bundlePath = NSBundle.mainBundle.bundlePath;
    if (bundleID.length == 0 ||
        ![bundlePath containsString:@"/var/containers/Bundle/Application/"] ||
        [bundlePath containsString:@"/System/"]) return NO;

    NSDictionary *store = [NSDictionary dictionaryWithContentsOfFile:CHStorePath];
    NSString *activeID = store[@"activeProfile"];
    if (activeID.length == 0) return NO;
    for (NSDictionary *profile in store[@"profiles"]) {
        if ([profile[@"id"] isEqual:activeID] && [profile[@"apps"] containsObject:bundleID]) return [profile[@"containerOptions"][@"containerProtection"] boolValue];
    }
    return NO;
}

%ctor {
    @autoreleasepool {
        CHContainerEnabled = CHIsSelectedUserApp();
        if (CHContainerEnabled) {
            CHResolvedContainerRoot = [CHContainerRoot() copy];
            NSString *root = CHResolvedContainerRoot;
            [[NSFileManager defaultManager] createDirectoryAtPath:root
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:nil];
            for (NSString *relative in @[@"Documents", @"Library", @"Library/Caches", @"Library/Preferences", @"tmp"]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:[root stringByAppendingPathComponent:relative]
                                           withIntermediateDirectories:YES attributes:nil error:nil];
            }
            CHInstallHook("open", (void *)&CHOpen, (void **)&CHOriginalOpen);
            CHInstallHook("openat", (void *)&CHOpenAt, (void **)&CHOriginalOpenAt);
            CHInstallHook("fopen", (void *)&CHFopen, (void **)&CHOriginalFopen);
            CHInstallHook("freopen", (void *)&CHFreopen, (void **)&CHOriginalFreopen);
            CHInstallHook("stat", (void *)&CHStat, (void **)&CHOriginalStat);
            CHInstallHook("lstat", (void *)&CHLstat, (void **)&CHOriginalLstat);
            CHInstallHook("fstatat", (void *)&CHFstatAt, (void **)&CHOriginalFstatAt);
            CHInstallHook("access", (void *)&CHAccess, (void **)&CHOriginalAccess);
            CHInstallHook("unlink", (void *)&CHUnlink, (void **)&CHOriginalUnlink);
            CHInstallHook("rename", (void *)&CHRename, (void **)&CHOriginalRename);
            CHInstallHook("mkdir", (void *)&CHMkdir, (void **)&CHOriginalMkdir);
            CHInstallHook("rmdir", (void *)&CHRmdir, (void **)&CHOriginalRmdir);
            CHInstallHook("opendir", (void *)&CHOpendir, (void **)&CHOriginalOpendir);
            CHInstallHook("readlink", (void *)&CHReadlink, (void **)&CHOriginalReadlink);
            CHInstallHook("chmod", (void *)&CHChmod, (void **)&CHOriginalChmod);
        }
    }
}
