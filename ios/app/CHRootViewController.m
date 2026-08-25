#import "CHRootViewController.h"
#import "CHProfileStore.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <MapKit/MapKit.h>

static NSArray<NSDictionary *> *CHInstalledApps(void) {
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    id workspace = [workspaceClass respondsToSelector:@selector(defaultWorkspace)] ? [workspaceClass performSelector:@selector(defaultWorkspace)] : nil;
    NSArray *installed = [workspace respondsToSelector:@selector(allInstalledApplications)] ? [workspace performSelector:@selector(allInstalledApplications)] : @[];
    NSMutableArray *result = [NSMutableArray array];
    for (id app in installed) {
        NSString *bundleID = [app valueForKey:@"applicationIdentifier"]; if (!bundleID.length) continue;
        [result addObject:@{@"name": [app valueForKey:@"localizedName"] ?: bundleID, @"bundleID": bundleID}];
    }
    [result sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) { return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]]; }];
    return result;
}

@interface CHAppPickerController : UITableViewController
@property(nonatomic, strong) CHProfileStore *store;
@property(nonatomic) NSUInteger profileIndex;
@property(nonatomic, copy) NSArray<NSDictionary *> *apps;
@end

@interface CHMapController : UIViewController <MKMapViewDelegate>
@property(nonatomic, strong) CHProfileStore *store;
@property(nonatomic) NSUInteger profileIndex;
@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) MKPointAnnotation *pin;
@property(nonatomic, strong) UILabel *selectionLabel;
@end

@interface CHRootViewController () <UIDocumentPickerDelegate>
@property(nonatomic, strong) CHProfileStore *store;
@end

@implementation CHAppPickerController
- (void)viewDidLoad { [super viewDidLoad]; self.title = @"Installed Apps"; self.apps = CHInstalledApps(); self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)]; self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.apps.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath { UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil]; NSDictionary *app = self.apps[indexPath.row]; cell.textLabel.text = app[@"name"]; cell.detailTextLabel.text = app[@"bundleID"]; if ([self.store.activeProfile[@"apps"] containsObject:app[@"bundleID"]]) cell.accessoryType = UITableViewCellAccessoryCheckmark; return cell; }
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { [self.store addBundleID:self.apps[indexPath.row][@"bundleID"] toProfileAtIndex:self.profileIndex]; [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone]; }
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
@end

@implementation CHMapController
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Location Testing"; self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectZero]; self.mapView.delegate = self; self.mapView.translatesAutoresizingMaskIntoConstraints = NO; [self.view addSubview:self.mapView];
    self.selectionLabel = [UILabel new]; self.selectionLabel.translatesAutoresizingMaskIntoConstraints = NO; self.selectionLabel.textAlignment = NSTextAlignmentCenter; self.selectionLabel.numberOfLines = 2; self.selectionLabel.backgroundColor = [UIColor.secondarySystemBackgroundColor colorWithAlphaComponent:.95]; [self.view addSubview:self.selectionLabel];
    [NSLayoutConstraint activateConstraints:@[[self.mapView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor], [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [self.mapView.bottomAnchor constraintEqualToAnchor:self.selectionLabel.topAnchor], [self.selectionLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [self.selectionLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [self.selectionLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor], [self.selectionLabel.heightAnchor constraintEqualToConstant:64]]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)]; self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveLocation)];
    [self.mapView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapTapped:)]];
    NSDictionary *location = self.store.activeProfile[@"location"]; CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([location[@"latitude"] doubleValue] ?: 34.0522, [location[@"longitude"] doubleValue] ?: -118.2437); self.pin = [MKPointAnnotation new]; self.pin.coordinate = coordinate; self.pin.title = location[@"label"] ?: @"Selected test location"; [self.mapView addAnnotation:self.pin]; [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(coordinate, 10000, 10000) animated:NO]; [self updateLabel:coordinate];
}
- (void)mapTapped:(UITapGestureRecognizer *)gesture { CLLocationCoordinate2D coordinate = [self.mapView convertPoint:[gesture locationInView:self.mapView] toCoordinateFromView:self.mapView]; self.pin.coordinate = coordinate; [self updateLabel:coordinate]; }
- (void)updateLabel:(CLLocationCoordinate2D)coordinate { self.selectionLabel.text = [NSString stringWithFormat:@"Tap the map to move the pin\n%.6f, %.6f", coordinate.latitude, coordinate.longitude]; }
- (void)saveLocation { CLLocationCoordinate2D c = self.pin.coordinate; [self.store setLatitude:c.latitude longitude:c.longitude label:@"Map selection" forProfileAtIndex:self.profileIndex]; [self close]; }
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
@end

@implementation CHRootViewController
- (void)viewDidLoad { [super viewDidLoad]; self.title = @"Chameleon"; self.store = [CHProfileStore new]; self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProfile)]; self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section == 0 ? 1 : (section == 1 ? self.store.profiles.count : 6); }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @[@"Status", @"Profiles", @"Tools"][section]; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil]; cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (indexPath.section == 0) { NSDictionary *active = self.store.activeProfile; cell.textLabel.text = active ? active[@"name"] : @"No active profile"; cell.detailTextLabel.text = active ? @"Active profile · runtime connected" : @"Create and activate a profile"; cell.imageView.image = [UIImage systemImageNamed:@"shield.fill"]; }
    else if (indexPath.section == 1) { NSDictionary *profile = self.store.profiles[indexPath.row]; BOOL active = [profile[@"id"] isEqual:self.store.activeProfileID]; cell.textLabel.text = profile[@"name"]; cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu apps assigned%@", (unsigned long)[profile[@"apps"] count], active ? @" · Active" : @""]; cell.imageView.image = [UIImage systemImageNamed:active ? @"checkmark.circle.fill" : @"person.crop.circle"]; }
    else { NSArray *titles = @[@"Assign App", @"Proxy", @"Location", @"Export Backup", @"Import Backup", @"Diagnostics"]; NSArray *icons = @[@"square.grid.2x2", @"network", @"location", @"square.and.arrow.up", @"square.and.arrow.down", @"stethoscope"]; cell.textLabel.text = titles[indexPath.row]; cell.imageView.image = [UIImage systemImageNamed:icons[indexPath.row]]; if ((indexPath.row == 1 || indexPath.row == 2) && self.store.activeProfile) { UISwitch *toggle = [UISwitch new]; toggle.tag = indexPath.row; NSDictionary *profile = self.store.activeProfile; toggle.on = indexPath.row == 1 ? [profile[@"proxy"][@"enabled"] boolValue] : [profile[@"location"][@"enabled"] boolValue]; [toggle addTarget:self action:@selector(featureToggled:) forControlEvents:UIControlEventValueChanged]; cell.accessoryView = toggle; cell.accessoryType = UITableViewCellAccessoryNone; cell.detailTextLabel.text = toggle.on ? (indexPath.row == 1 ? [NSString stringWithFormat:@"Enabled · %@", profile[@"proxy"][@"host"] ?: @"Configured"] : [NSString stringWithFormat:@"Testing enabled · %@", profile[@"location"][@"label"] ?: @"Map pin"]) : @"Disabled"; } }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { [tableView deselectRowAtIndexPath:indexPath animated:YES]; if (indexPath.section == 1) { [self.store activateProfileAtIndex:indexPath.row]; [tableView reloadData]; return; } if (indexPath.section != 2) return; if (!self.store.activeProfile && indexPath.row < 3) { [self alert:@"No active profile" message:@"Create and activate a profile first."]; return; } switch (indexPath.row) { case 0: [self assignApp]; break; case 1: [self configureProxy]; break; case 2: [self configureLocation]; break; case 3: [self exportBackup]; break; case 4: [self importBackup]; break; default: [self showDiagnostics]; } }
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath { if (indexPath.section == 1 && style == UITableViewCellEditingStyleDelete) { [self.store deleteProfileAtIndex:indexPath.row]; [tableView reloadData]; } }
- (NSUInteger)activeIndex { return [self.store.profiles indexOfObjectPassingTest:^BOOL(NSDictionary *p, NSUInteger idx, BOOL *stop) { return [p[@"id"] isEqual:self.store.activeProfileID]; }]; }
- (void)featureToggled:(UISwitch *)sender { if (sender.tag == 1) [self.store setProxyEnabled:sender.on forProfileAtIndex:self.activeIndex]; else [self.store setLocationEnabled:sender.on forProfileAtIndex:self.activeIndex]; [self.tableView reloadData]; }
- (void)addProfile { [self prompt:@"New Profile" fields:@[@"Name"] completion:^(NSArray *v) { if ([v[0] length]) { [self.store addProfileNamed:v[0]]; [self.tableView reloadData]; } }]; }
- (void)assignApp { CHAppPickerController *picker = [CHAppPickerController new]; picker.store = self.store; picker.profileIndex = self.activeIndex; [self presentViewController:[[UINavigationController alloc] initWithRootViewController:picker] animated:YES completion:nil]; }
- (void)configureProxy { UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Proxy" message:@"Optional credentials are stored in the active profile." preferredStyle:UIAlertControllerStyleAlert]; for (NSString *placeholder in @[@"Host", @"Port", @"Username (optional)", @"Password (optional)"]) [a addTextFieldWithConfigurationHandler:^(UITextField *t) { t.placeholder = placeholder; t.secureTextEntry = [placeholder hasPrefix:@"Password"]; }]; NSDictionary *proxy = self.store.activeProfile[@"proxy"]; NSArray *values = @[proxy[@"host"] ?: @"", proxy[@"port"] ? [proxy[@"port"] stringValue] : @"", proxy[@"username"] ?: @"", proxy[@"password"] ?: @""]; [a.textFields enumerateObjectsUsingBlock:^(UITextField *t, NSUInteger i, BOOL *stop) { t.text = values[i]; }]; [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]]; [a addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { [self.store setProxyHost:a.textFields[0].text port:[a.textFields[1].text integerValue] username:a.textFields[2].text password:a.textFields[3].text forProfileAtIndex:self.activeIndex]; [self.tableView reloadData]; }]]; [self presentViewController:a animated:YES completion:nil]; }
- (void)configureLocation { CHMapController *map = [CHMapController new]; map.store = self.store; map.profileIndex = self.activeIndex; [self presentViewController:[[UINavigationController alloc] initWithRootViewController:map] animated:YES completion:nil]; }
- (void)exportBackup { UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[[self.store exportBackup]] applicationActivities:nil]; [self presentViewController:share animated:YES completion:nil]; }
- (void)importBackup { UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeJSON, UTTypeData] asCopy:YES]; picker.delegate = self; picker.allowsMultipleSelection = NO; [self presentViewController:picker animated:YES completion:nil]; }
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls { NSError *error = nil; if (urls.firstObject && [self.store importBackupFromURL:urls.firstObject error:&error]) { [self.tableView reloadData]; [self alert:@"Backup Imported" message:@"Profiles and settings were restored."]; } else [self alert:@"Import Failed" message:error.localizedDescription ?: @"The selected backup could not be imported."]; }
- (void)showDiagnostics { UIDevice *device = UIDevice.currentDevice; device.batteryMonitoringEnabled = YES; NSProcessInfo *process = NSProcessInfo.processInfo; NSString *vendorID = device.identifierForVendor.UUIDString ?: @"Unavailable"; NSDictionary *r = self.store.runtime; NSString *message = [NSString stringWithFormat:@"Model: %@\nSystem: %@\nName: %@\nIdentifier for Vendor: %@\nScreen: %.0f × %.0f\nBattery: %@\nLocale: %@\nTimezone: %@\nMemory: %.1f GB\nFree disk: %.1f GB\nRuntime: %@\nProfiles: %lu\n\nIMEI, serial number and hardware UDID are protected by iOS and intentionally are not collected or exposed.", device.model, device.systemVersion, device.name, vendorID, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height, device.batteryState == UIDeviceBatteryStateUnknown ? @"Unknown" : [NSString stringWithFormat:@"%.0f%%", device.batteryLevel * 100], NSLocale.currentLocale.localeIdentifier, NSTimeZone.localTimeZone.name, process.physicalMemory / 1073741824.0, [self freeDiskGB], r.count ? @"Connected" : @"Waiting for respring", (unsigned long)self.store.profiles.count]; [self alert:@"Diagnostics" message:message]; }
- (double)freeDiskGB { NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/" error:nil]; return [attrs[NSFileSystemFreeSize] doubleValue] / 1073741824.0; }
- (void)prompt:(NSString *)title fields:(NSArray<NSString *> *)fields completion:(void (^)(NSArray<NSString *> *))completion { UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert]; for (NSString *f in fields) [a addTextFieldWithConfigurationHandler:^(UITextField *t) { t.placeholder = f; }]; [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]]; [a addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) { NSMutableArray *v = [NSMutableArray array]; for (UITextField *t in a.textFields) [v addObject:t.text ?: @""]; completion(v); }]]; [self presentViewController:a animated:YES completion:nil]; }
- (void)alert:(NSString *)title message:(NSString *)message { UIAlertController *a = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert]; [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]]; [self presentViewController:a animated:YES completion:nil]; }
@end
