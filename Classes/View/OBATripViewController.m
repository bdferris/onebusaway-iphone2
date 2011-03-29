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


@implementation OBATripViewController

@synthesize appContext;
@synthesize mapView;
@synthesize currentLocationButton;
@synthesize editButton;

-(void) dealloc {
	self.appContext = nil;
    self.mapView = nil;
    self.currentLocationButton = nil;
    self.editButton = nil;
    [super dealloc];
}

- (void) viewDidLoad {
	[super viewDidLoad];
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
    return nil;
}

-(IBAction) onCrossHairsButton:(id)sender {
    
}

-(IBAction) onEditButton:(id)sender {
    OBAPlanTripViewController * vc = [OBAPlanTripViewController viewControllerWithApplicationContext:self.appContext];
    [self.navigationController pushViewController:vc animated:TRUE];
}


@end

