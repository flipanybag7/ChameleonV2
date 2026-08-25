#import "CHRootViewController.h"
#import "CHProfileStore.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface CHRootViewController () <UIDocumentPickerDelegate>
@property(nonatomic, strong) CHProfileStore *store;
@end

@implementation CHRootViewController
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Chameleon"; self.store = [CHProfileStore new];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProfile)];
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 1 : (section == 1 ? self.store.profiles.count : 6); }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @[@"Status", @"Profiles", @"Tools"][section]; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil]; cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (indexPath.section == 0) {
        NSDictionary *active = self.store.activeProfile; cell.textLabel.text = active ? active[@"name"] : @"No active profile"; cell.detailTextLabel.text = active ? @"Active profile · runtime connected" : @"Create and activate a profile"; cell.imageView.image = [UIImage systemImageNamed:@"shield.fill"];
    } else if (indexPath.section == 1) {
        NSDictionary *profile = self.store.profiles[indexPath.row]; BOOL active = [profile[@"id"] isEqual:self.store.activeProfileID]; cell.textLabel.text = profile[@"name"]; cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu apps assigned%@", (unsigned long)[profile[@"apps"] count], active ? @" · Active" : @""]; cell.imageView.image = [UIImage systemImageNamed:active ? @"checkmark.circle.fill" : @"person.crop.circle"];
    } else {
        NSArray *titles = @[@"Assign App", @"Proxy", @"Location", @"Export Backup", @"Import Backup", @"Diagnostics"]; NSArray *icons = @[@"square.grid.2x2", @"network", @"location", @"square.and.arrow.up", @"square.and.arrow.down", @"stethoscope"];
        cell.textLabel.text = titles[indexPath.row]; cell.imageView.image = [UIImage systemImageNamed:icons[indexPath.row]];
        if ((indexPath.row == 1 || indexPath.row == 2) && self.store.activeProfile) {
            UISwitch *toggle = [UISwitch new]; toggle.tag = indexPath.row;
            NSDictionary *profile = self.store.activeProfile;
            toggle.on = indexPath.row == 1 ? [profile[@"proxy"][@"enabled"] boolValue] : [profile[@"location"][@"enabled"] boolValue];
            [toggle addTarget:self action:@selector(featureToggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle; cell.accessoryType = UITableViewCellAccessoryNone;
            if (indexPath.row == 1) {
                NSString *host = profile[@"proxy"][@"host"] ?: @"Not configured";
                cell.detailTextLabel.text = toggle.on ? [NSString stringWithFormat:@"Enabled · %@", host] : @"Disabled";
            } else {
                NSString *label = profile[@"location"][@"label"] ?: @"Not configured";
                cell.detailTextLabel.text = toggle.on ? [NSString stringWithFormat:@"Testing enabled · %@", label] : @"Disabled";
            }
        }
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) { [self.store activateProfileAtIndex:indexPath.row]; [tableView reloadData]; return; }
    if (indexPath.section != 2) return;
    if (!self.store.activeProfile && indexPath.row < 3) { [self alert:@"No active profile" message:@"Create and activate a profile first."]; return; }
    switch (indexPath.row) { case 0: [self assignApp]; break; case 1: [self configureProxy]; break; case 2: [self configureLocation]; break; case 3: [self exportBackup]; break; case 4: [self importBackup]; break; default: [self showDiagnostics]; }
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath { if (indexPath.section == 1 && style == UITableViewCellEditingStyleDelete) { [self.store deleteProfileAtIndex:indexPath.row]; [tableView reloadData]; } }
- (NSUInteger)activeIndex { return [self.store.profiles indexOfObjectPassingTest:^BOOL(NSDictionary *p, NSUInteger idx, BOOL *stop) { return [p[@"id"] isEqual:self.store.activeProfileID]; }]; }
- (void)featureToggled:(UISwitch *)sender {
    if (sender.tag == 1) [self.store setProxyEnabled:sender.on forProfileAtIndex:self.activeIndex];
    else [self.store setLocationEnabled:sender.on forProfileAtIndex:self.activeIndex];
    [self.tableView reloadData];
}
- (void)addProfile { [self prompt:@"New Profile" fields:@[@"Name"] completion:^(NSArray *v) { if ([v[0] length]) { [self.store addProfileNamed:v[0]]; [self.tableView reloadData]; } }]; }
- (void)assignApp { [self prompt:@"Assign App" fields:@[@"Bundle ID (e.g. com.example.app)"] completion:^(NSArray *v) { if ([v[0] length]) { [self.store addBundleID:v[0] toProfileAtIndex:self.activeIndex]; [self.tableView reloadData]; } }]; }
- (void)configureProxy { [self prompt:@"Proxy" fields:@[@"Host", @"Port"] completion:^(NSArray *v) { [self.store setProxyHost:v[0] port:[v[1] integerValue] forProfileAtIndex:self.activeIndex]; }]; }
- (void)configureLocation { [self prompt:@"Location" fields:@[@"Latitude", @"Longitude", @"Label"] completion:^(NSArray *v) { [self.store setLatitude:[v[0] doubleValue] longitude:[v[1] doubleValue] label:v[2] forProfileAtIndex:self.activeIndex]; }]; }
- (void)exportBackup { UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[[self.store exportBackup]] applicationActivities:nil]; [self presentViewController:share animated:YES completion:nil]; }
- (void)importBackup { UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeJSON, UTTypeData] asCopy:YES]; picker.delegate = self; picker.allowsMultipleSelection = NO; [self presentViewController:picker animated:YES completion:nil]; }
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls { NSError *error = nil; if (urls.firstObject && [self.store importBackupFromURL:urls.firstObject error:&error]) { [self.tableView reloadData]; [self alert:@"Backup Imported" message:@"Profiles and settings were restored."]; } else { [self alert:@"Import Failed" message:error.localizedDescription ?: @"The selected backup could not be imported."]; } }
- (void)showDiagnostics { NSDictionary *r = self.store.runtime; NSString *message = [NSString stringWithFormat:@"Runtime: %@\nVersion: %@\nProfiles: %lu\nActive ID: %@", r.count ? @"Connected" : @"Waiting for respring", r[@"version"] ?: @"—", (unsigned long)self.store.profiles.count, self.store.activeProfileID.length ? self.store.activeProfileID : @"—"]; [self alert:@"Diagnostics" message:message]; }
- (void)prompt:(NSString *)title fields:(NSArray<NSString *> *)fields completion:(void (^)(NSArray<NSString *> *))completion { UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert]; for (NSString *f in fields) [a addTextFieldWithConfigurationHandler:^(UITextField *t) { t.placeholder = f; }]; [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]]; [a addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { NSMutableArray *v=[NSMutableArray array]; for(UITextField *t in a.textFields)[v addObject:t.text ?: @""]; completion(v); }]]; [self presentViewController:a animated:YES completion:nil]; }
- (void)alert:(NSString *)title message:(NSString *)message { UIAlertController *a=[UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert]; [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]]; [self presentViewController:a animated:YES completion:nil]; }
@end
