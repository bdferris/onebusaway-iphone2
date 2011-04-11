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

- (NSArray*) annotationsForTripState:(OBATripState*)state;
- (NSArray*) overlaysForItinerary:(OBAItineraryV2*)itinerary;
    
@end


@implementation OBATripViewController

@synthesize appContext;
@synthesize tripController;
@synthesize tableView;
@synthesize mapView;
@synthesize refreshButton;
@synthesize editButton;
@synthesize leftButton;
@synthesize currentLocationButton;
@synthesize rightButton;

-(void) dealloc {
    
    _tripStateTableViewCellFactory = [NSObject releaseOld:_tripStateTableViewCellFactory retainNew:nil];
    _currentItinerary = [NSObject releaseOld:_currentItinerary retainNew:nil];
    
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
    self.refreshButton.enabled = FALSE;
    self.leftButton.enabled = FALSE;
    self.currentLocationButton.enabled = FALSE;
    self.rightButton.enabled = FALSE;

    self.tripController = self.appContext.tripController;
    self.tripController.delegate = self;
    
    _tripStateTableViewCellFactory = [[OBATripStateTableViewCellFactory alloc] initWithAppContext:self.appContext navigationController:self.navigationController tableView:self.tableView];
    _currentItinerary = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSIndexPath * indexPath = [self.tableView indexPathForSelectedRow];
    if( indexPath )
        [self.tableView deselectRowAtIndexPath:indexPath animated:FALSE];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}



#pragma mark OBATripViewController

-(IBAction) onRefreshButton:(id)sender {
    [self.tripController refresh];
}

-(IBAction) onEditButton:(id)sender {
    OBAPlanTripViewController * vc = [OBAPlanTripViewController viewControllerWithApplicationContext:self.appContext];
    [vc setTripQuery:self.tripController.query];
    [self.navigationController pushViewController:vc animated:TRUE];
}

-(IBAction) onLeftButton:(id)sender {
    [self.tripController moveToPrevState];
}

-(IBAction) onCrossHairsButton:(id)sender {
    [self.tripController moveToCurrentState];
}

-(IBAction) onRightButton:(id)sender {
    [self.tripController moveToNextState];
}

-(IBAction) onBookmakrButton:(id)sender {
    OBABookmarksViewController * vc = [[OBABookmarksViewController alloc] initWithApplicationContext:self.appContext];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:TRUE];
    [vc release];
}

-(IBAction) onSettingsButton:(id)sender {
    OBAMoreViewController * vc = [[OBAMoreViewController alloc] initWithAppContext:self.appContext];
    [self.navigationController pushViewController:vc animated:TRUE];
    [vc release];
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

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id<MKAnnotation>)annotation {    
	if( [annotation isKindOfClass:[OBAPlaceAnnotation class]] ) {
		MKPinAnnotationView * view = (MKPinAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"OBAPlaceAnnotation"];
		if( view == nil ) {
			view = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"OBAPlaceAnnotation"] autorelease];
		}
		view.canShowCallout = TRUE;
		view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        view.pinColor = MKPinAnnotationColorGreen;
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

-(void) chooseFromItineraries:(NSArray*)itineraries {
    OBAPickTripViewController * vc = [[OBAPickTripViewController alloc] initWithAppContext:self.appContext];
    [self.navigationController popToRootViewController];
    [self.navigationController pushViewController:vc animated:TRUE];
    [vc release];
}

-(void) refreshTripState:(OBATripState*)state {
    
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
    if( _currentItinerary != state.itinerary ) {
        NSArray * annotations = [self annotationsForTripState:state];
        NSArray* overlays = [self overlaysForItinerary:state.itinerary];        
        [mv removeOverlays:mv.overlays];
        [mv removeAnnotations:mv.annotations];
        [mv addOverlays:overlays];
        [mv addAnnotations:annotations];
    }
    
    _currentItinerary = [NSObject releaseOld:_currentItinerary retainNew:state.itinerary];
    
    [mv setRegion:state.region animated:TRUE];
}

#pragma mark OBABookmarkViewControllerDelegate

- (void) placeBookmarkSelected:(OBAPlace*)place {
    OBAPlace * placeFrom = [OBAPlace placeWithCurrentLocation];
    OBATripQuery * query = [[OBATripQuery alloc] initWithPlaceFrom:placeFrom placeTo:place time:[OBATargetTime timeNow]];
    query.automaticallyPickBestItinerary = TRUE;
    [self.tripController planTripWithQuery:query];
    [query release];
}

@end




@implementation OBATripViewController (Private)
                             
- (NSArray*) annotationsForTripState:(OBATripState*)state {
    
    NSMutableArray * annotations = [NSMutableArray array];
    
    OBAPlaceAnnotation * placeFromAnnotation = [[OBAPlaceAnnotation alloc] initWithPlace:state.placeFrom];
    OBAPlaceAnnotation * placeToAnnotation = [[OBAPlaceAnnotation alloc] initWithPlace:state.placeTo];
    [annotations addObject:placeFromAnnotation];
    [annotations addObject:placeToAnnotation];
    [placeFromAnnotation release];
    [placeToAnnotation release];
    
    OBAItineraryV2 * itinerary = state.itinerary;
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

@end


