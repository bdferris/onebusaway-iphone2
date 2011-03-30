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
#import "OBATripPolyline.h"


@implementation OBATripViewController

@synthesize appContext;
@synthesize tripController;
@synthesize mapView;
@synthesize currentLocationButton;
@synthesize editButton;
@synthesize leftButton;
@synthesize rightButton;

-(void) dealloc {
	self.appContext = nil;
    self.mapView = nil;
    self.currentLocationButton = nil;
    self.editButton = nil;
    self.leftButton = nil;
    self.rightButton = nil;
    [super dealloc];
}

- (void) viewDidLoad {
	[super viewDidLoad];
    self.leftButton.enabled = FALSE;
    self.rightButton.enabled = FALSE;

    self.tripController = self.appContext.tripController;
    self.tripController.delegate = self;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

#pragma mark MKMapViewDelegate Methods

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {

}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {    
	return nil;
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id )overlay {

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

-(void) refreshTrip {
    MKMapView * mv = self.mapView;
    [mv removeOverlays:mv.overlays];
    [mv addOverlays:[self.tripController overlays]];
}

-(IBAction) onCrossHairsButton:(id)sender {
    
}

-(IBAction) onEditButton:(id)sender {
    OBAPlanTripViewController * vc = [OBAPlanTripViewController viewControllerWithApplicationContext:self.appContext];
    [self.navigationController pushViewController:vc animated:TRUE];
}

-(IBAction) onLeftButton:(id)sender {
    
}

-(IBAction) onRightButton:(id)sender {
    
}

-(IBAction) onBookmakrButton:(id)sender {
    
}

@end

