#import "CHMapController.h"
#import "CHProfileStore.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface CHMapController () <MKMapViewDelegate>
@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) MKPointAnnotation *pin;
@property(nonatomic, strong) UILabel *selectionLabel;
@property(nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation CHMapController
- (void)viewDidLoad {
    [super viewDidLoad]; self.title = @"Choose Location"; self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.locationManager = [CLLocationManager new]; [self.locationManager requestWhenInUseAuthorization];
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectZero]; self.mapView.delegate = self; self.mapView.translatesAutoresizingMaskIntoConstraints = NO; self.mapView.showsCompass = YES; self.mapView.showsUserLocation = YES; self.mapView.layer.cornerRadius = 18; self.mapView.layer.masksToBounds = YES; [self.view addSubview:self.mapView];
    self.selectionLabel = [UILabel new]; self.selectionLabel.translatesAutoresizingMaskIntoConstraints = NO; self.selectionLabel.textAlignment = NSTextAlignmentCenter; self.selectionLabel.numberOfLines = 2; self.selectionLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]; self.selectionLabel.backgroundColor = UIColor.secondarySystemBackgroundColor; self.selectionLabel.layer.cornerRadius = 16; self.selectionLabel.layer.masksToBounds = YES; [self.view addSubview:self.selectionLabel];
    [NSLayoutConstraint activateConstraints:@[[self.mapView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12], [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12], [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12], [self.mapView.bottomAnchor constraintEqualToAnchor:self.selectionLabel.topAnchor constant:-12], [self.selectionLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12], [self.selectionLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12], [self.selectionLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12], [self.selectionLabel.heightAnchor constraintEqualToConstant:68]]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)]; self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveLocation)];
    [self.mapView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapTapped:)]];
    NSDictionary *location = self.store.activeProfile[@"location"]; double latitude = [location[@"latitude"] doubleValue], longitude = [location[@"longitude"] doubleValue]; if (latitude == 0 && longitude == 0) { latitude = 34.0522; longitude = -118.2437; }
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude); self.pin = [MKPointAnnotation new]; self.pin.coordinate = coordinate; self.pin.title = @"Selected location"; [self.mapView addAnnotation:self.pin]; [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(coordinate, 12000, 12000) animated:NO]; [self updateLabel:coordinate];
}
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation { if (annotation != self.pin) return nil; MKMarkerAnnotationView *view = (MKMarkerAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"]; if (!view) view = [[MKMarkerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"]; view.annotation = annotation; view.markerTintColor = UIColor.systemGreenColor; view.glyphImage = [UIImage systemImageNamed:@"location.fill"]; view.draggable = YES; return view; }
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState { if (newState == MKAnnotationViewDragStateEnding || newState == MKAnnotationViewDragStateNone) [self updateLabel:self.pin.coordinate]; }
- (void)mapTapped:(UITapGestureRecognizer *)gesture { if (gesture.state != UIGestureRecognizerStateEnded) return; CLLocationCoordinate2D coordinate = [self.mapView convertPoint:[gesture locationInView:self.mapView] toCoordinateFromView:self.mapView]; self.pin.coordinate = coordinate; [self updateLabel:coordinate]; }
- (void)updateLabel:(CLLocationCoordinate2D)coordinate { self.selectionLabel.text = [NSString stringWithFormat:@"Tap or drag the pin\n%.6f, %.6f", coordinate.latitude, coordinate.longitude]; }
- (void)saveLocation { CLLocationCoordinate2D c = self.pin.coordinate; [self.store setLatitude:c.latitude longitude:c.longitude label:@"Map selection" forProfileAtIndex:self.profileIndex]; [self close]; }
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
@end
