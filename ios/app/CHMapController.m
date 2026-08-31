#import "CHMapController.h"
#import "CHProfileStore.h"
#import <MapKit/MapKit.h>

@interface CHMapController () <MKMapViewDelegate, UISearchBarDelegate>
@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) MKPointAnnotation *pin;
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UISearchController *searchController;
@property(nonatomic, assign) CLLocationCoordinate2D selectedCoordinate;
@property(nonatomic, copy) NSString *selectedPlaceLabel;
@end

@implementation CHMapController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Choose Location";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveLocation)];

    self.mapView = [MKMapView new];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.showsCompass = YES;
    self.mapView.showsScale = YES;
    [self.view addSubview:self.mapView];

    self.statusLabel = [UILabel new];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.backgroundColor = [UIColor colorWithWhite:.08 alpha:.88];
    self.statusLabel.textColor = UIColor.whiteColor;
    self.statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.layer.cornerRadius = 12;
    self.statusLabel.layer.masksToBounds = YES;
    [self.view addSubview:self.statusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.mapView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mapView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:12],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-12],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12],
        [self.statusLabel.heightAnchor constraintGreaterThanOrEqualToConstant:48]
    ]];

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = @"Search a street or city";
    self.searchController.searchBar.delegate = self;
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;

    NSDictionary *location = self.profileIndex < self.store.profiles.count ? self.store.profiles[self.profileIndex][@"location"] : nil;
    double latitude = [location[@"latitude"] doubleValue];
    double longitude = [location[@"longitude"] doubleValue];
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180 || (latitude == 0 && longitude == 0)) {
        latitude = 34.016127;
        longitude = -118.291403;
    }
    self.selectedPlaceLabel = [location[@"label"] length] ? location[@"label"] : @"Map selection";
    [self selectCoordinate:CLLocationCoordinate2DMake(latitude, longitude) label:self.selectedPlaceLabel center:YES];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapTapped:)];
    tap.cancelsTouchesInView = NO;
    [self.mapView addGestureRecognizer:tap];
}

- (void)selectCoordinate:(CLLocationCoordinate2D)coordinate label:(NSString *)label center:(BOOL)center {
    self.selectedCoordinate = coordinate;
    self.selectedPlaceLabel = label.length ? label : @"Map selection";
    if (!self.pin) {
        self.pin = [MKPointAnnotation new];
        [self.mapView addAnnotation:self.pin];
    }
    self.pin.coordinate = coordinate;
    self.pin.title = self.selectedPlaceLabel;
    self.statusLabel.text = [NSString stringWithFormat:@"%@\n%.6f, %.6f", self.selectedPlaceLabel, coordinate.latitude, coordinate.longitude];
    if (center) [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(coordinate, 8000, 8000) animated:NO];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (annotation != self.pin) return nil;
    static NSString *identifier = @"ChameleonLocationPin";
    MKMarkerAnnotationView *view = (MKMarkerAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!view) view = [[MKMarkerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
    view.annotation = annotation;
    view.draggable = YES;
    view.canShowCallout = YES;
    view.markerTintColor = [UIColor colorWithRed:.10 green:.78 blue:.48 alpha:1];
    return view;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if (newState == MKAnnotationViewDragStateEnding || newState == MKAnnotationViewDragStateCanceling) {
        [self selectCoordinate:view.annotation.coordinate label:@"Map selection" center:NO];
        view.dragState = MKAnnotationViewDragStateNone;
    }
}

- (void)mapTapped:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) return;
    CGPoint point = [gesture locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    [self selectCoordinate:coordinate label:@"Map selection" center:NO];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *query = [searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!query.length) return;
    [searchBar resignFirstResponder];
    self.statusLabel.text = @"Searching…";
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = query;
    request.region = self.mapView.region;
    [[[MKLocalSearch alloc] initWithRequest:request] startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !response.mapItems.count) {
                self.statusLabel.text = error.localizedDescription ?: @"No matching location";
                return;
            }
            UIAlertController *results = [UIAlertController alertControllerWithTitle:@"Search Results" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            NSUInteger count = MIN((NSUInteger)6, response.mapItems.count);
            for (NSUInteger i = 0; i < count; i++) {
                MKMapItem *item = response.mapItems[i];
                NSString *name = item.name.length ? item.name : query;
                [results addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self selectCoordinate:item.placemark.coordinate label:name center:YES];
                    self.searchController.active = NO;
                }]];
            }
            [results addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            results.popoverPresentationController.sourceView = self.view;
            results.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), 1, 1, 1);
            [self presentViewController:results animated:YES completion:nil];
        });
    }];
}

- (void)saveLocation {
    [self.store setLatitude:self.selectedCoordinate.latitude longitude:self.selectedCoordinate.longitude label:self.selectedPlaceLabel ?: @"Map selection" forProfileAtIndex:self.profileIndex];
    [self close];
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

@end
