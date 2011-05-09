/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBATripViewController.h"
#import "OBAPlanTripViewController.h"
#import "OBAPickTripViewController.h"
#import "OBAPlaceAnnotationViewController.h"
#import "OBAMoreViewController.h"
#import "OBASphericalGeometryLibrary.h"

#import "OBAPlaceAnnotation.h"
#import "OBATripPolyline.h"
#import "OBAStopIconFactory.h"


@interface OBATripViewController (Private)

- (void) showNoTripsFoundWarning;

- (void) refreshUI;
- (void) clearRefreshUITimer;

- (NSArray*) annotationsForTripState:(OBATripState*)state;
- (NSArray*) overlaysForItinerary:(OBAItineraryV2*)itinerary;
    
@end


@implementation OBATripViewController

@synthesize appContext;
@synthesize tripController;
@synthesize locationManager;

@synthesize tableView;
@synthesize mapView;
@synthesize refreshButton;
@synthesize editButton;
@synthesize leftButton;
@synthesize currentLocationButton;
@synthesize rightButton;

-(void) dealloc {
    
    [self clearRefreshUITimer];

    [_mapRegionManager release];
    [_tripStateTableViewCellFactory release];

    [_currentItinerary release];
    
    [_timeFormatter release];
    [_tripStateOverlays release];
    [_tripStateAnnotations release];
    [_droppedPinAnnotations release];
    
	self.appContext = nil;
    self.mapView = nil;
    self.refreshButton = nil;
    self.editButton = nil;
    self.leftButton = nil;
    self.currentLocationButton = nil;
    self.rightButton = nil;
    
    [super dealloc];
}

- (void) viewDidLoad {
	[super viewDidLoad];
    
    self.locationManager = self.appContext.locationManager;
    
    self.refreshButton.enabled = FALSE;
    self.leftButton.enabled = FALSE;
    self.rightButton.enabled = FALSE;

    self.tripController = self.appContext.tripController;
    
    _mapRegionManager = [[OBAMapRegionManager alloc] initWithMapView:self.mapView];
    _mapRegionManager.lastRegionChangeWasProgramatic = TRUE;
    
    _tripStateTableViewCellFactory = [[OBATripStateTableViewCellFactory alloc] initWithAppContext:self.appContext navigationController:self.navigationController tableView:self.tableView];
    
    _currentQueryIndex = self.tripController.queryIndex - 1;
    _currentItinerary = nil;
    
    _timeFormatter = [[NSDateFormatter alloc] init];
    [_timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    self.mapView.showsUserLocation = TRUE;

    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                      initWithTarget:self 
                                                      action:@selector(handleMapLongPressGesture:)];
    longPressGesture.minimumPressDuration = 1.0;
    
    [self.mapView addGestureRecognizer:longPressGesture];
    [longPressGesture release];
    
    _droppedPinAnnotations = [[NSMutableArray alloc] init];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tripController.delegate = self;
    
    NSIndexPath * indexPath = [self.tableView indexPathForSelectedRow];
    if( indexPath )
        [self.tableView deselectRowAtIndexPath:indexPath animated:FALSE];

    [self clearRefreshUITimer];
    _uiRefreshTimer = [[NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(refreshUI) userInfo:nil repeats:TRUE] retain];
    
    OBAModelDAO * modelDao = self.appContext.modelDao;
    for( OBAPlace * place in modelDao.droppedPins ) {
        OBAPlaceAnnotation * annotation = [[OBAPlaceAnnotation alloc] initWithPlace:place];
        [_droppedPinAnnotations addObject:annotation];        
    }
    [self.mapView addAnnotations:_droppedPinAnnotations];
     
    [modelDao addObserver:self forKeyPath:@"droppedPins" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {    
	[super viewWillDisappear:animated];
    self.tripController.delegate = nil;
    
    OBAModelDAO * modelDao = self.appContext.modelDao;
    [modelDao removeObserver:self forKeyPath:@"droppedPins"];
    
    [self.mapView removeAnnotations:_droppedPinAnnotations];
    [_droppedPinAnnotations removeAllObjects];
}



#pragma mark OBATripViewController

-(IBAction) onRefreshButton:(id)sender {
    self.refreshButton.enabled = FALSE;
    [self.tripController refresh];
}

-(IBAction) onEditButton:(id)sender {
    OBAPlanTripViewController * vc = [OBAPlanTripViewController viewControllerWithApplicationContext:self.appContext];
    [vc setTripQuery:self.tripController.query];
    [self.navigationController pushViewController:vc animated:TRUE];
}

-(IBAction) onLeftButton:(id)sender {
    _mapRegionManager.lastRegionChangeWasProgramatic = TRUE;
    [self.tripController moveToPrevState];
}

-(IBAction) onCrossHairsButton:(id)sender {
    
    _mapRegionManager.lastRegionChangeWasProgramatic = TRUE;
    
    if( [self.tripController hasCurrentState] ) {
        [self.tripController moveToCurrentState];
    }
    else {
        CLLocation * location = self.locationManager.currentLocation;
        if( location ) {
            double radius = location.horizontalAccuracy;
            MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:location.coordinate latRadius:radius lonRadius:radius];
            [_mapRegionManager setRegion:region];
        }
    }
        
}

-(IBAction) onRightButton:(id)sender {
    _mapRegionManager.lastRegionChangeWasProgramatic = TRUE;
    [self.tripController moveToNextState];
}

-(IBAction) onBookmakrButton:(id)sender {
    [OBABookmarksViewController showBookmarksViewControllerWithAppContext:self.appContext parent:self.navigationController delegate:self includeCurrentLocation:FALSE];
}

-(IBAction) onSettingsButton:(id)sender {
    OBAMoreViewController * vc = [[OBAMoreViewController alloc] initWithAppContext:self.appContext];
    [self.navigationController pushViewController:vc animated:TRUE];
    [vc release];
}

-(IBAction) handleMapLongPressGesture:(UILongPressGestureRecognizer*)sender {
    if( sender.state != UIGestureRecognizerStateBegan )
        return;

    CGPoint touchPoint = [sender locationInView:self.mapView];   
    CLLocationCoordinate2D c = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];

    CLLocation * location = [[CLLocation alloc] initWithLatitude:c.latitude longitude:c.longitude];
    
    OBAModelDAO * modelDao = self.appContext.modelDao;
    [modelDao addDroppedPin:location];
    
    [location release];
}


#pragma mark UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    OBATripController * tc = self.tripController;
    OBATripState * state = [tc tripState];
    return [_tripStateTableViewCellFactory getNumberOfRowsForTripState:state];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_tripStateTableViewCellFactory getCellForState:self.tripController.tripState indexPath:indexPath];
}

#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tripStateTableViewCellFactory didSelectRowForState:self.tripController.tripState indexPath:indexPath];
}

#pragma mark MKMapViewDelegate Methods

- (void)mapView:(MKMapView *)mv regionWillChangeAnimated:(BOOL)animated {
    [_mapRegionManager mapView:mv regionWillChangeAnimated:animated];
}

- (void)mapView:(MKMapView *)mv regionDidChangeAnimated:(BOOL)animated {
    [_mapRegionManager mapView:mv regionDidChangeAnimated:animated];
}

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id<MKAnnotation>)annotation {    
	if( [annotation isKindOfClass:[OBAPlaceAnnotation class]] ) {
        
        OBAPlaceAnnotation * placeAnnotation = annotation;
        OBAPlace * place = placeAnnotation.place;
        
		MKPinAnnotationView * view = (MKPinAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"OBAPlaceAnnotation"];
		if( view == nil ) {
			view = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"OBAPlaceAnnotation"] autorelease];
		}
		view.canShowCallout = TRUE;
		view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        view.pinColor = MKPinAnnotationColorGreen;
        view.animatesDrop = placeAnnotation.animatesDrop;
        
        if (place.isDroppedPin) {
            view.pinColor = MKPinAnnotationColorPurple;
        }
            
		return view;                                     
    }
    else if( [annotation isKindOfClass:[OBAStopV2 class]] ) {
        OBAStopV2 * stop = (OBAStopV2*)annotation;
        static NSString * viewId = @"StopView";
        
		MKAnnotationView * view = [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
        if( view == nil ) {
            view = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId] autorelease];
        }
        view.canShowCallout = TRUE;
        view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        OBAStopIconFactory * stopIconFactory = self.appContext.stopIconFactory;
        view.image = [stopIconFactory getIconForStop:stop];
        return view;

    }
    return nil;
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	id<MKAnnotation> annotation = view.annotation;
    if ([annotation isKindOfClass:[OBAPlaceAnnotation class]]) {
        OBAPlaceAnnotation * placeAnnotation = (OBAPlaceAnnotation*) annotation;
        OBAPlaceAnnotationViewController * vc = [[OBAPlaceAnnotationViewController alloc] initWithAppContext:self.appContext place:placeAnnotation.place];
        [self.navigationController pushViewController:vc animated:TRUE];
        [vc release];
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay {

    if( [overlay isKindOfClass:[MKPolyline class]] ) {
        MKPolylineView * pv = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
        pv.fillColor = [UIColor blackColor];
        pv.strokeColor = [UIColor blackColor];
        pv.lineWidth = 5;
        return pv;
	}
    else if( [overlay isKindOfClass:[OBATripPolyline class]] ) {
        OBATripPolyline * tp = overlay;
        MKPolylineView * pv = [[MKPolylineView alloc] initWithPolyline:tp.polyline];
        UIColor * color = ( tp.polylineType == OBATripPolylineTypeTransitLeg ) ? [UIColor blueColor] : [UIColor blackColor];
        pv.fillColor = color;
        pv.strokeColor = color;
        pv.alpha = 0.75;
        pv.lineWidth = 5;
        return pv;
	}
	
	return nil;	

}



#pragma mark OBATripControllerDelegate

-(void) refreshingItineraries {
    self.refreshButton.enabled = FALSE;
    self.navigationItem.title = @"Updating...";
}

-(void) refreshingItinerariesCompleted {
    
    self.refreshButton.enabled = TRUE;
    
    if ( self.tripController.lastUpdate ) {
        NSString * t = [_timeFormatter stringFromDate:self.tripController.lastUpdate];
        self.navigationItem.title = [NSString stringWithFormat:@"Updated: %@",t];
    }

    if ([self.tripController.itineraries count] == 0 )
        [self showNoTripsFoundWarning];
    
    if (_currentQueryIndex != self.tripController.queryIndex) {
        _currentQueryIndex = self.tripController.queryIndex;
        _mapRegionManager.lastRegionChangeWasProgramatic = TRUE;
    }
}

-(void) refreshingItinerariesFailed:(NSError*)error {
    self.refreshButton.enabled = TRUE;
    self.navigationItem.title = @"Error updating...";
    OBALogDebugWithError(error, @"Error updating...");
}

-(void) chooseFromItineraries:(NSArray*)itineraries {
    OBAPickTripViewController * vc = [[OBAPickTripViewController alloc] initWithAppContext:self.appContext];
    [self.navigationController popToRootViewController];
    [self.navigationController pushViewController:vc animated:TRUE];
    [vc release];
}

-(void) refreshTripState:(OBATripState*)state {
    
    if ( self.tripController.lastUpdate ) {
        NSString * t = [_timeFormatter stringFromDate:self.tripController.lastUpdate];
        self.navigationItem.title = [NSString stringWithFormat:@"Updated: %@",t];
    }

    // Make sure our view controller is visible
    [self.navigationController popToRootViewController];
    
    // Reload the trip summary table
    [self.tableView reloadData];
    
    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.height = [_tripStateTableViewCellFactory getNumberOfRowsForTripState:self.tripController.tripState] * 44;
    
    CGRect mapFrame = self.mapView.frame;
    double maxY = CGRectGetMaxY(mapFrame);
    mapFrame.origin.y = CGRectGetMaxY(tableFrame) + 1;
    mapFrame.size.height = maxY - mapFrame.origin.y;
 
    // We record this here, since the animated map frame resizing will wipe out the value
    BOOL lastRegionChangeWasProgramatic  = _mapRegionManager.lastRegionChangeWasProgramatic;

    [UIView animateWithDuration:0.25 animations:^{
        self.tableView.frame = tableFrame;
        self.mapView.frame = mapFrame;
    }];
    
    MKMapView * mv = self.mapView;
    
    OBATripController * tc = self.tripController;
    
    self.refreshButton.enabled = TRUE;
    self.leftButton.enabled = tc.hasPreviousState;
    self.currentLocationButton.enabled = tc.hasCurrentState;
    self.rightButton.enabled = tc.hasNextState;
    
    // We only need to update overlays and annotations if the itinerary has changed
    if( _currentItinerary != state.itinerary || state.itinerary == nil) {
        NSArray * annotations = [self annotationsForTripState:state];
        NSArray* overlays = [self overlaysForItinerary:state.itinerary];
        
        if( _tripStateOverlays )
            [mv removeOverlays:_tripStateOverlays];
        _tripStateOverlays = [NSObject releaseOld:_tripStateOverlays retainNew:overlays];
        [mv addOverlays:_tripStateOverlays];
        
        if( _tripStateAnnotations )
            [mv removeAnnotations:_tripStateAnnotations];
        _tripStateAnnotations = [NSObject releaseOld:_tripStateAnnotations retainNew:annotations];        
        [mv addAnnotations:_tripStateAnnotations];
    }
    
    _currentItinerary = [NSObject releaseOld:_currentItinerary retainNew:state.itinerary];
    
    if (lastRegionChangeWasProgramatic) {
        [_mapRegionManager setRegion:state.region];
    }
}

#pragma mark OBABookmarkViewControllerDelegate

- (void) placeBookmarkSelected:(OBAPlace*)place {
    OBAPlace * placeFrom = [OBAPlace placeWithCurrentLocation];
    OBATripQuery * query = [[OBATripQuery alloc] initWithPlaceFrom:placeFrom placeTo:place time:[OBATargetTime timeNow]];
    query.automaticallyPickBestItinerary = TRUE;
    [self.tripController planTripWithQuery:query];
    [query release];
}

#pragma mark Key-Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"Hey!");
    NSNumber * kind = [change objectForKey:NSKeyValueChangeKindKey];
    switch ([kind intValue]) {
        case NSKeyValueChangeInsertion: {
            NSArray * newDroppedPins = [change objectForKey:NSKeyValueChangeNewKey];
            for (OBAPlace * place in newDroppedPins) {
                OBAPlaceAnnotation * annotation = [[OBAPlaceAnnotation alloc] initWithPlace:place];
                annotation.animatesDrop = TRUE;
                [self.mapView addAnnotation:annotation];
                [annotation release];
            }
            break;
        }
        case NSKeyValueChangeRemoval: {
            NSArray * newDroppedPins = [change objectForKey:NSKeyValueChangeOldKey];
            NSLog(@"What?");
            break;
        }            
        default:
            break;
    }
}

@end




@implementation OBATripViewController (Private)

- (void) refreshUI {
    [self.tableView reloadData];
}

- (void) clearRefreshUITimer {
    [_uiRefreshTimer invalidate];
    [_uiRefreshTimer release];
    _uiRefreshTimer = nil;
}
                             
- (NSArray*) annotationsForTripState:(OBATripState*)state {
    
    NSMutableArray * annotations = [NSMutableArray array];
    
    if( ! state.placeFrom.isDroppedPin ) {
        OBAPlaceAnnotation * placeFromAnnotation = [[OBAPlaceAnnotation alloc] initWithPlace:state.placeFrom];
        [annotations addObject:placeFromAnnotation];
        [placeFromAnnotation release];
    }
    
    if( ! state.placeTo.isDroppedPin ) {
        OBAPlaceAnnotation * placeToAnnotation = [[OBAPlaceAnnotation alloc] initWithPlace:state.placeTo];
        [annotations addObject:placeToAnnotation];
        [placeToAnnotation release];
    }
    
    OBAItineraryV2 * itinerary = state.itinerary;
    
    if( itinerary ) {
        NSMutableSet * stopIds = [NSMutableSet set];
        
        for( OBALegV2 * leg in itinerary.legs ) {
            if( leg.transitLeg ) {
                OBATransitLegV2 * transitLeg = leg.transitLeg;
                OBAStopV2 * fromStop = transitLeg.fromStop;
                OBAStopV2 * toStop = transitLeg.toStop;
                if( fromStop && ! [stopIds containsObject:fromStop.stopId]) {
                    [annotations addObject:fromStop];
                    [stopIds addObject:fromStop.stopId];
                }
                if( toStop && ! [stopIds containsObject:toStop.stopId] ) {
                    [annotations addObject:toStop];
                    [stopIds addObject:toStop.stopId];
                }
            }
        }
    }
    
    return annotations;
}

- (NSArray*) overlaysForItinerary:(OBAItineraryV2*)itinerary {
    
    NSMutableArray * list = [NSMutableArray array];
    for( OBALegV2 * leg in itinerary.legs ) {
        if( leg.transitLeg ) {
            OBATransitLegV2 * transitLeg = leg.transitLeg;
            if( transitLeg.path ) {
                NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:transitLeg.path];
                MKPolyline * polyline = [OBASphericalGeometryLibrary createMKPolylineFromLocations:points];
                OBATripPolyline * tripPolyline = [OBATripPolyline tripPolyline:polyline type:OBATripPolylineTypeTransitLeg];                    
                [list addObject:tripPolyline];
            }
        }
        if ([leg.streetLegs count] > 0 ) {
            NSMutableArray * allPoints = [NSMutableArray array];
            for( OBAStreetLegV2 * streetLeg in leg.streetLegs ) {
                if( streetLeg.path ) {
                    NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:streetLeg.path];
                    [allPoints addObjectsFromArray:points];
                }
            }
            if( [allPoints count] > 0 ) {
                MKPolyline * polyline = [OBASphericalGeometryLibrary createMKPolylineFromLocations:allPoints];
                OBATripPolyline * tripPolyline = [OBATripPolyline tripPolyline:polyline type:OBATripPolylineTypeStreetLeg]; 
                [list addObject:tripPolyline];
            }
        }
    }
    
    return list;
}

- (void) showNoTripsFoundWarning {
    UIAlertView * view = [[UIAlertView alloc] init];
    view.title = @"No Trips Found";
    view.message = @"We could not find any trips for your search request.";
    [view addButtonWithTitle:@"Dismiss"];
    view.cancelButtonIndex = 0;
    [view show];
    [view release];
}

@end


