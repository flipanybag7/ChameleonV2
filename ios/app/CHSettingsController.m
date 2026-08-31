#import "CHSettingsController.h"
#import "CHProfileStore.h"
#import "CHDeviceInformationProvider.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface CHSettingsController () <UIDocumentPickerDelegate>
@property(nonatomic, strong) CHProfileStore *store;
@property(nonatomic, copy) NSDictionary<NSString *, NSString *> *deviceIdentifiers;
@end

@implementation CHSettingsController

- (instancetype)initWithStore:(CHProfileStore *)store {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) _store = store;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.tableView.backgroundColor = UIColor.blackColor;
    self.deviceIdentifiers = [CHDeviceInformationProvider deviceIdentifiers];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 4; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 2 : (section == 1 ? 4 : (section == 2 ? 2 : 1)); }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @[@"Backup management", @"Device identifiers", @"Diagnostics", @"Runtime boundaries"][section]; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) return @"Exports profiles, selected apps, containers, network/location settings, and local test fixtures as JSON.";
    if (section == 1) return @"Read-only values reported locally by the device. Chameleon does not modify, save, or include them in backups. iOS may restrict one or more values.";
    if (section == 3) return @"Filesystem separation is app-scoped user-space pathname interposition, not a replacement for the iOS kernel sandbox.";
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.backgroundColor = [UIColor colorWithWhite:.11 alpha:1];
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (indexPath.section == 0) {
        cell.textLabel.text = indexPath.row == 0 ? @"Export backup" : @"Import backup";
        cell.detailTextLabel.text = indexPath.row == 0 ? @"Share a portable JSON backup" : @"Validate and restore a JSON backup";
        cell.imageView.image = [UIImage systemImageNamed:indexPath.row == 0 ? @"square.and.arrow.up" : @"square.and.arrow.down"];
    } else if (indexPath.section == 1) {
        NSArray<NSString *> *labels = @[@"Serial number", @"IMEI", @"MEID", @"Wi-Fi MAC"];
        NSArray<NSString *> *keys = @[@"serial", @"imei", @"meid", @"wifiMAC"];
        cell.textLabel.text = labels[indexPath.row];
        cell.detailTextLabel.text = self.deviceIdentifiers[keys[indexPath.row]] ?: @"Unavailable";
        cell.detailTextLabel.numberOfLines = 1;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.imageView.image = [UIImage systemImageNamed:@"iphone.gen3"];
    } else if (indexPath.section == 2) {
        cell.textLabel.text = indexPath.row == 0 ? @"Runtime status" : @"Active profile fixtures";
        cell.detailTextLabel.text = indexPath.row == 0 ? @"Component version and last start" : @"Serial, IMEI, MEID, MAC, and PPI";
        cell.imageView.image = [UIImage systemImageNamed:indexPath.row == 0 ? @"waveform.path.ecg" : @"list.bullet.rectangle"];
    } else {
        cell.textLabel.text = @"Isolation details";
        cell.detailTextLabel.text = @"See what is covered by this build";
        cell.imageView.image = [UIImage systemImageNamed:@"shield.lefthalf.filled"];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) [self exportBackup]; else [self importBackup];
    } else if (indexPath.section == 1) {
        return;
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) [self showRuntime]; else [self showFixtures];
    } else {
        [self showBoundaries];
    }
}

- (void)exportBackup {
    NSURL *url = [self.store exportBackup];
    if (!url) { [self alert:@"Export Failed" message:@"The backup file could not be created."]; return; }
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    activity.popoverPresentationController.sourceView = self.view;
    activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - 40, 1, 1);
    [self presentViewController:activity animated:YES completion:nil];
}

- (void)importBackup {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeJSON, UTTypeData] asCopy:YES];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSError *error = nil;
    if (urls.firstObject && [self.store importBackupFromURL:urls.firstObject error:&error]) {
        [self.tableView reloadData];
        [self alert:@"Backup Imported" message:[NSString stringWithFormat:@"Restored %lu profile%@.", (unsigned long)self.store.profiles.count, self.store.profiles.count == 1 ? @"" : @"s"]];
    } else {
        [self alert:@"Import Failed" message:error.localizedDescription ?: @"The selected file is not a valid Chameleon backup."];
    }
}

- (void)showRuntime {
    NSDictionary *runtime = self.store.runtime;
    NSTimeInterval stamp = [runtime[@"lastStart"] doubleValue];
    NSString *lastStart = stamp > 0 ? [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:stamp] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle] : @"Not recorded";
    NSString *message = [NSString stringWithFormat:@"Component: %@\nVersion: %@\nLast start: %@\nActive profile: %@\nActive container: %@", runtime[@"component"] ?: @"Not loaded", runtime[@"version"] ?: @"Unknown", lastStart, runtime[@"activeProfile"] ?: @"None", runtime[@"activeContainer"] ?: @"None"];
    [self alert:@"Runtime Status" message:message];
}

- (void)showFixtures {
    NSDictionary *device = [self.store activeProfile][@"device"];
    if (!device) { [self alert:@"Active Profile Fixtures" message:@"Select an active profile first."]; return; }
    NSString *(^value)(NSString *) = ^NSString *(NSString *key) { NSString *text = [[device objectForKey:key] description]; return text.length ? text : @"Not set"; };
    NSString *message = [NSString stringWithFormat:@"Serial: %@\nIMEI: %@\nMEID: %@\nWi-Fi MAC: %@\nPPI: %@\n\nThese are profile fixtures and are not returned by private modem, baseband, or hardware-integrity interfaces.", value(@"serialFixture"), value(@"imeiFixture"), value(@"meidFixture"), value(@"wifiMACFixture"), value(@"ppi")];
    [self alert:@"Active Profile Fixtures" message:message];
}

- (void)showBoundaries {
    [self alert:@"Isolation Details" message:@"This build redirects common pathname-based file operations inside the selected app's home directory. File descriptors already opened by another API, memory-mapped files, direct syscalls, and kernel sandbox policy remain outside this layer. Proxy support applies to standard NSURLSession configurations; custom sockets and embedded networking stacks may bypass it."];
}

- (void)alert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
