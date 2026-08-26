#import "CHMapController.h"
#import "CHProfileStore.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface CHMapController () <MKMapViewDelegate, CLLocationManagerDelegate, MKLocalSearchCompleterDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) MKPointAnnotation *pin;
@property(nonatomic, strong) UILabel *selectionLabel;
@property(nonatomic, strong) UILabel *mapStatusLabel;
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, strong) UISearchBar *searchBar;
@property(nonatomic, strong) UITableView *resultsTable;
@property(nonatomic, strong) MKLocalSearchCompleter *searchCompleter;
@property(nonatomic, copy) NSArray<MKLocalSearchCompletion *> *searchResults;
@property(nonatomic, copy) NSString *selectedPlaceLabel;
@property(nonatomic, assign) CLLocationCoordinate2D selectedCoordinate;
@property(nonatomic, assign) BOOL hasStoredLocation;
@property(nonatomic, assign) BOOL regionConfigured;
@end

@implementation CHMapController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Choose Location";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.searchCompleter = [MKLocalSearchCompleter new];
    self.searchCompleter.delegate = self;

    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    CLAuthorizationStatus authorizationStatus = self.locationManager.authorizationStatus;
    if (authorizationStatus == kCLAuthorizationStatusNotDetermined) [self.locationManager requestWhenInUseAuthorization];
    else if (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways) [self.locationManager startUpdatingLocation];

    self.searchBar = [UISearchBar new];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.placeholder = @"Search a street or city";
    self.searchBar.delegate = self;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    [self.view addSubview:self.searchBar];

    self.mapView = [[MKMapView alloc] initWithFrame:CGRectZero];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.showsCompass = YES;
    self.mapView.showsScale = YES;
    self.mapView.showsUserLocation = (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways);
    self.mapView.backgroundColor = [UIColor colorWithWhite:.90 alpha:1];
    self.mapView.layer.cornerRadius = 18;
    self.mapView.layer.masksToBounds = YES;
    [self.view addSubview:self.mapView];

    self.resultsTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.resultsTable.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultsTable.delegate = self;
    self.resultsTable.dataSource = self;
    self.resultsTable.hidden = YES;
    self.resultsTable.layer.cornerRadius = 12;
    self.resultsTable.layer.masksToBounds = YES;
    self.resultsTable.layer.shadowOpacity = .18;
    [self.view addSubview:self.resultsTable];

    self.mapStatusLabel = [UILabel new];
    self.mapStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapStatusLabel.text = @"Loading map…";
    self.mapStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.mapStatusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.mapStatusLabel.textColor = UIColor.secondaryLabelColor;
    self.mapStatusLabel.backgroundColor = [UIColor.secondarySystemBackgroundColor colorWithAlphaComponent:.92];
    self.mapStatusLabel.layer.cornerRadius = 12;
    self.mapStatusLabel.layer.masksToBounds = YES;
    [self.view addSubview:self.mapStatusLabel];

    self.selectionLabel = [UILabel new];
    self.selectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectionLabel.textAlignment = NSTextAlignmentCenter;
    self.selectionLabel.numberOfLines = 2;
    self.selectionLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.selectionLabel.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.selectionLabel.layer.cornerRadius = 16;
    self.selectionLabel.layer.masksToBounds = YES;
    [self.view addSubview:self.selectionLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.searchBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:4],
        [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:8],
        [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8],
        [self.searchBar.heightAnchor constraintEqualToConstant:48],
        [self.mapView.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor constant:4],
        [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [self.mapView.bottomAnchor constraintEqualToAnchor:self.selectionLabel.topAnchor constant:-12],
        [self.selectionLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [self.selectionLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [self.selectionLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12],
        [self.selectionLabel.heightAnchor constraintEqualToConstant:68],
        [self.resultsTable.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor],
        [self.resultsTable.leadingAnchor constraintEqualToAnchor:self.searchBar.leadingAnchor constant:8],
        [self.resultsTable.trailingAnchor constraintEqualToAnchor:self.searchBar.trailingAnchor constant:-8],
        [self.resultsTable.heightAnchor constraintLessThanOrEqualToConstant:250],
        [self.mapStatusLabel.centerXAnchor constraintEqualToAnchor:self.mapView.centerXAnchor],
        [self.mapStatusLabel.topAnchor constraintEqualToAnchor:self.mapView.topAnchor constant:12],
        [self.mapStatusLabel.heightAnchor constraintEqualToConstant:28],
        [self.mapStatusLabel.widthAnchor constraintGreaterThanOrEqualToConstant:120]
    ]];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveLocation)];
    [self.mapView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapTapped:)]];

    NSDictionary *location = self.store.activeProfile[@"location"];
    double latitude = [location[@"latitude"] doubleValue], longitude = [location[@"longitude"] doubleValue];
    self.hasStoredLocation = CLLocationCoordinate2DIsValid(CLLocationCoordinate2DMake(latitude, longitude)) && !(latitude == 0 && longitude == 0);
    if (!self.hasStoredLocation) { latitude = 37.3319; longitude = -122.0315; }
    self.selectedCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    self.selectedPlaceLabel = location[@"label"] ?: @"Map selection";
    self.pin = [MKPointAnnotation new];
    self.pin.coordinate = self.selectedCoordinate;
    self.pin.title = @"Selected location";
    [self.mapView addAnnotation:self.pin];
    [self updateRegion:self.selectedCoordinate animated:NO];
    [self updateLabel:self.selectedCoordinate];
}

- (void)viewDidAppear:(BOOL)animated { [super viewDidAppear:animated]; [self.view layoutIfNeeded]; [self updateRegion:self.selectedCoordinate animated:NO]; }
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; if (self.mapView.bounds.size.width > 0 && self.mapView.bounds.size.height > 0 && !self.regionConfigured) [self updateRegion:self.selectedCoordinate animated:NO]; }
- (void)updateRegion:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated { if (!CLLocationCoordinate2DIsValid(coordinate) || self.mapView.bounds.size.width <= 0) return; self.regionConfigured = YES; [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(coordinate, 12000, 12000) animated:animated]; }

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (annotation != self.pin) return nil;
    MKMarkerAnnotationView *view = (MKMarkerAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
    if (!view) view = [[MKMarkerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
    view.annotation = annotation; view.markerTintColor = UIColor.systemGreenColor; view.glyphImage = [UIImage systemImageNamed:@"location.fill"]; view.draggable = YES; return view;
}
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView { self.mapStatusLabel.hidden = YES; NSLog(@"[Chameleon] MapKit finished loading map"); }
- (void)mapView:(MKMapView *)mapView didFailLoadingMapWithError:(NSError *)error { [self mapViewDidFailLoadingMap:mapView withError:error]; }
- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error { self.mapStatusLabel.hidden = NO; self.mapStatusLabel.text = @"Map tiles unavailable"; self.selectionLabel.text = [NSString stringWithFormat:@"Map tiles unavailable.\\nSearch still works when online. %@", error.localizedDescription ?: @""]; NSLog(@"[Chameleon] MapKit failed to load map tiles: %@", error); }
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState { if (newState == MKAnnotationViewDragStateEnding || newState == MKAnnotationViewDragStateNone) { self.selectedCoordinate = self.pin.coordinate; self.selectedPlaceLabel = @"Map selection"; [self updateLabel:self.selectedCoordinate]; } }
- (void)mapTapped:(UITapGestureRecognizer *)gesture { if (gesture.state != UIGestureRecognizerStateEnded) return; CLLocationCoordinate2D coordinate = [self.mapView convertPoint:[gesture locationInView:self.mapView] toCoordinateFromView:self.mapView]; if (!CLLocationCoordinate2DIsValid(coordinate)) return; self.selectedCoordinate = coordinate; self.selectedPlaceLabel = @"Map selection"; self.pin.coordinate = coordinate; [self updateLabel:coordinate]; }

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText { self.searchCompleter.queryFragment = searchText.length >= 2 ? searchText : @""; self.resultsTable.hidden = searchText.length < 2; if (searchText.length < 2) { self.searchResults = @[]; [self.resultsTable reloadData]; } }
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar { [searchBar resignFirstResponder]; if (self.searchResults.count) [self searchCompletion:self.searchResults.firstObject]; }
- (void)searchCompleterDidUpdateResults:(MKLocalSearchCompleter *)completer { self.searchResults = completer.results ?: @[]; self.resultsTable.hidden = self.searchResults.count == 0; [self.resultsTable reloadData]; }
- (void)searchCompleter:(MKLocalSearchCompleter *)completer didFailWithError:(NSError *)error { self.searchResults = @[]; self.resultsTable.hidden = YES; self.selectionLabel.text = [NSString stringWithFormat:@"Search unavailable.\\n%@", error.localizedDescription ?: @"Check the network"]; NSLog(@"[Chameleon] Search failed: %@", error); }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.searchResults.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath { UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil]; MKLocalSearchCompletion *result = self.searchResults[indexPath.row]; cell.textLabel.text = result.title; cell.detailTextLabel.text = result.subtitle; cell.imageView.image = [UIImage systemImageNamed:@"mappin.and.ellipse"]; return cell; }
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { [self searchCompletion:self.searchResults[indexPath.row]]; }
- (void)searchCompletion:(MKLocalSearchCompletion *)completion { self.resultsTable.hidden = YES; [self.searchBar resignFirstResponder]; MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] initWithCompletion:completion]; MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request]; self.mapStatusLabel.hidden = NO; self.mapStatusLabel.text = @"Finding location…"; [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) { dispatch_async(dispatch_get_main_queue(), ^{ if (error || !response.mapItems.count) { self.mapStatusLabel.text = @"Location not found"; self.selectionLabel.text = @"No matching location found.\\nTry a fuller street or city name."; return; } MKMapItem *item = response.mapItems.firstObject; self.selectedCoordinate = item.placemark.coordinate; self.selectedPlaceLabel = item.name.length ? item.name : completion.title; self.pin.coordinate = self.selectedCoordinate; [self updateRegion:self.selectedCoordinate animated:YES]; [self updateLabel:self.selectedCoordinate]; self.mapStatusLabel.hidden = YES; }); }]; }

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager { CLAuthorizationStatus status = manager.authorizationStatus; if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) { self.mapView.showsUserLocation = YES; [manager startUpdatingLocation]; } else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted) { self.mapView.showsUserLocation = NO; NSLog(@"[Chameleon] Location permission unavailable (status %ld); map selection remains available.", (long)status); } }
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations { if (self.hasStoredLocation || locations.count == 0) return; CLLocation *location = locations.lastObject; if (location.horizontalAccuracy < 0) return; self.selectedCoordinate = location.coordinate; self.pin.coordinate = location.coordinate; [self updateRegion:location.coordinate animated:YES]; [self updateLabel:location.coordinate]; self.hasStoredLocation = YES; [manager stopUpdatingLocation]; }
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error { NSLog(@"[Chameleon] Location update failed: %@", error); }
- (void)updateLabel:(CLLocationCoordinate2D)coordinate { self.selectionLabel.text = [NSString stringWithFormat:@"%@\\n%.6f, %.6f", self.selectedPlaceLabel ?: @"Tap or drag the pin", coordinate.latitude, coordinate.longitude]; }
- (void)saveLocation { CLLocationCoordinate2D c = self.selectedCoordinate; [self.store setLatitude:c.latitude longitude:c.longitude label:self.selectedPlaceLabel ?: @"Map selection" forProfileAtIndex:self.profileIndex]; [self close]; }
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
@end
