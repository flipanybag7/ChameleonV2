#import "CHMapController.h"
#import "CHProfileStore.h"
#import <MapKit/MapKit.h>
#import <WebKit/WebKit.h>

@interface CHMapController () <WKNavigationDelegate, WKScriptMessageHandler, UISearchBarDelegate>
@property(nonatomic, strong) WKWebView *webView;
@property(nonatomic, strong) UISearchController *searchController;
@property(nonatomic, assign) CLLocationCoordinate2D selectedCoordinate;
@property(nonatomic, copy) NSString *selectedPlaceLabel;
@property(nonatomic, assign) BOOL mapReady;
@end

@implementation CHMapController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Choose Location";
    self.view.backgroundColor = [UIColor colorWithWhite:.08 alpha:1];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveLocation)];

    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    WKUserContentController *messages = [WKUserContentController new];
    [messages addScriptMessageHandler:self name:@"location"];
    configuration.userContentController = messages;
    configuration.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.navigationDelegate = self;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor colorWithWhite:.08 alpha:1];
    [self.view addSubview:self.webView];
    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
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
    self.selectedCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    self.selectedPlaceLabel = [location[@"label"] length] ? location[@"label"] : @"Map selection";

    NSString *leafletPath = [NSBundle.mainBundle pathForResource:@"leaflet" ofType:@"js" inDirectory:@"Leaflet/dist"];
    NSURL *baseURL = leafletPath.length ? [[NSURL fileURLWithPath:leafletPath] URLByDeletingLastPathComponent] : NSBundle.mainBundle.bundleURL;
    [self.webView loadHTMLString:[self htmlForLatitude:latitude longitude:longitude label:self.selectedPlaceLabel] baseURL:baseURL];
}

- (NSString *)JSONString:(NSString *)value {
    NSData *data = [NSJSONSerialization dataWithJSONObject:@[value ?: @""] options:0 error:nil];
    NSString *array = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"[\"\"]";
    return [array substringWithRange:NSMakeRange(1, array.length - 2)];
}

- (NSString *)htmlForLatitude:(double)latitude longitude:(double)longitude label:(NSString *)label {
    return [NSString stringWithFormat:@"<!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no'><link rel='stylesheet' href='leaflet.css'><style>html,body,#map{height:100%%;width:100%%;margin:0}body{background:#161a1d}#map{background-color:#1c2226;background-image:linear-gradient(#ffffff0c 1px,transparent 1px),linear-gradient(90deg,#ffffff0c 1px,transparent 1px);background-size:32px 32px}.leaflet-container{font-family:-apple-system;color:#111}#status{position:fixed;z-index:9999;left:12px;right:12px;bottom:14px;min-height:28px;padding:10px;border-radius:12px;background:#111e;color:#fff;text-align:center;font:13px -apple-system;box-sizing:border-box}</style></head><body><div id='map'></div><div id='status'>Starting bundled map…</div><script src='leaflet.js'></script><script>const start=[%.8f,%.8f];let chosen=start;let chosenLabel=%@;let map,marker;const status=document.getElementById('status');function report(lat,lon,label){chosen=[lat,lon];chosenLabel=label||'Map selection';marker.setLatLng(chosen);marker.bindPopup(chosenLabel);status.textContent=chosenLabel+' · '+lat.toFixed(6)+', '+lon.toFixed(6);window.webkit.messageHandlers.location.postMessage({lat:lat,lon:lon,label:chosenLabel,ready:true});}function setPoint(lat,lon,label,center){if(center)map.setView([lat,lon],15);report(lat,lon,label)}function boot(){if(typeof L==='undefined'){status.textContent='Bundled map engine missing — reinstall Chameleon';return}map=L.map('map',{zoomControl:true}).setView(start,13);const tiles=L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19,attribution:'© OpenStreetMap contributors',crossOrigin:true});let loaded=false;tiles.on('load',()=>{loaded=true;status.textContent='Tap the map or drag the pin'});tiles.on('tileerror',()=>{if(!loaded)status.textContent='Map tiles unavailable — check the phone network'});tiles.addTo(map);marker=L.marker(start,{draggable:true}).addTo(map);marker.on('dragend',()=>{const p=marker.getLatLng();report(p.lat,p.lng,'Map selection')});map.on('click',e=>report(e.latlng.lat,e.latlng.lng,'Map selection'));setTimeout(()=>map.invalidateSize(true),100);report(start[0],start[1],chosenLabel)}window.addEventListener('load',boot);</script></body></html>", latitude, longitude, [self JSONString:label]];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [webView evaluateJavaScript:@"typeof L !== 'undefined'" completionHandler:^(id value, NSError *error) {
        self.mapReady = [value boolValue] && !error;
    }];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self showError:[NSString stringWithFormat:@"Map page failed to load: %@", error.localizedDescription]];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self showError:[NSString stringWithFormat:@"Map page failed to start: %@", error.localizedDescription]];
}

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Map Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqual:@"location"] || ![message.body isKindOfClass:NSDictionary.class]) return;
    NSDictionary *body = message.body;
    self.mapReady = [body[@"ready"] boolValue];
    self.selectedCoordinate = CLLocationCoordinate2DMake([body[@"lat"] doubleValue], [body[@"lon"] doubleValue]);
    self.selectedPlaceLabel = [body[@"label"] length] ? body[@"label"] : @"Map selection";
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *query = [searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!query.length) return;
    [searchBar resignFirstResponder];
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = query;
    [[[MKLocalSearch alloc] initWithRequest:request] startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !response.mapItems.count) { [self showError:error.localizedDescription ?: @"No matching location was found."]; return; }
            UIAlertController *results = [UIAlertController alertControllerWithTitle:@"Search Results" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            NSUInteger count = MIN((NSUInteger)6, response.mapItems.count);
            for (NSUInteger index = 0; index < count; index++) {
                MKMapItem *item = response.mapItems[index];
                NSString *name = item.name.length ? item.name : query;
                [results addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    CLLocationCoordinate2D coordinate = item.placemark.coordinate;
                    NSString *script = [NSString stringWithFormat:@"setPoint(%.8f,%.8f,%@,true)", coordinate.latitude, coordinate.longitude, [self JSONString:name]];
                    [self.webView evaluateJavaScript:script completionHandler:nil];
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
    if (!self.mapReady) { [self showError:@"The map has not finished loading. Reopen the picker after checking the phone's network connection."]; return; }
    [self.store setLatitude:self.selectedCoordinate.latitude longitude:self.selectedCoordinate.longitude label:self.selectedPlaceLabel ?: @"Map selection" forProfileAtIndex:self.profileIndex];
    [self close];
}

- (void)close {
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"location"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc { [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"location"]; }

@end
