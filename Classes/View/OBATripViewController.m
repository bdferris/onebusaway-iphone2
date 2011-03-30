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


@interface OBATripViewController (Private)

-(UILabel*) getItineraryTripDepartureLabel:(OBATripState*)state;
-(NSString*) getItineraryTripDepartureLabelText:(OBATripState*)state;
-(UILabel*) getItineraryTripArrivalLabel:(OBATripState*)state;
-(NSString*) getItineraryTripArrivalLabelText:(OBATripState*)state;
-(void) showInfoOverlay:(BOOL)show clear:(BOOL)clear;

@end


@implementation OBATripViewController

@synthesize appContext;
@synthesize tripController;
@synthesize mapView;
@synthesize currentLocationButton;
@synthesize editButton;
@synthesize leftButton;
@synthesize rightButton;

-(void) dealloc {
    
    [_infoOverlay release];
    _infoOverlay = nil;
    
    [_timeFormatter release];
    _timeFormatter = nil;
    
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
    
    CGRect bounds = self.view.bounds;
    
    _infoOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), 64)];
    _infoOverlay.backgroundColor = [UIColor colorWithWhite:0.25 alpha:0.8];
    _infoOverlayVisible = FALSE;
    
    _timeFormatter = [[NSDateFormatter alloc] init];
    [_timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [_timeFormatter setTimeStyle:NSDateFormatterShortStyle];

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



#pragma mark OBATripViewController

-(IBAction) onEditButton:(id)sender {
    OBAPlanTripViewController * vc = [OBAPlanTripViewController viewControllerWithApplicationContext:self.appContext];
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
    
    OBATripController * tc = self.tripController;
    
    self.leftButton.enabled = tc.hasPreviousState;
    self.rightButton.enabled = tc.hasNextState;
    
    OBATripState * state = tc.tripState;
    
    if( state ) {        
        [mv addOverlays:state.overlays];
        [mv setRegion:state.preferredRegion animated:TRUE];
        [self showInfoOverlay:TRUE clear:TRUE];
        switch(state.type) {
            case OBATripStateTypeCompleteItinerary: {

                UILabel * departureLabel = [self getItineraryTripDepartureLabel:state];
                UILabel * arrivalLabel = [self getItineraryTripArrivalLabel:state];

                [departureLabel setOrigin:CGPointMake(10, 10)];
                [arrivalLabel setOrigin:CGPointMake(10, CGRectGetMaxY(departureLabel.bounds) + 10)];
                
                [_infoOverlay addSubview:departureLabel];
                [_infoOverlay addSubview:arrivalLabel];
                break;
            }
        }
    }
}

@end




@implementation OBATripViewController (Private)

-(UILabel*) getItineraryTripDepartureLabel:(OBATripState*)state {
    UILabel * label = [[[UILabel alloc] init] autorelease];
    label.text = [self getItineraryTripDepartureLabelText:state];
    label.font = [UIFont boldSystemFontOfSize:16];
    label.backgroundColor = [UIColor clearColor];
    label.shadowColor     = [UIColor colorWithWhite:0.0 alpha:0.5];
    label.textColor       = [UIColor whiteColor];
    [label sizeToFit];
    return label;
}

-(NSString*) getItineraryTripDepartureLabelText:(OBATripState*)state {
    OBAItineraryV2 * itinerary = state.itinerary;
    NSDate * startTime = itinerary.startTime;
    NSTimeInterval interval = [startTime timeIntervalSinceNow];
    NSInteger mins = interval / 60;
    if( -1 <= mins && mins <= 1 ) {
        return @"Depart now!";
    }
    else if( 1 < mins && mins <= 50 ) {
        return [NSString stringWithFormat:@"Depart in %d minutes", mins];
    }
    else if( 50 < mins ) {
        return [NSString stringWithFormat:@"Depart at %@",[_timeFormatter stringFromDate:startTime]];
    }
    else if( -50 <= mins && mins < -1 ) {
        return [NSString stringWithFormat:@"Departed %d minutes ago", (-mins)];
    }
    else {
        return [NSString stringWithFormat:@"Departed at %@",[_timeFormatter stringFromDate:startTime]];
    }
}

-(UILabel*) getItineraryTripArrivalLabel:(OBATripState*)state {
    UILabel * label = [[[UILabel alloc] init] autorelease];
    label.text = [self getItineraryTripArrivalLabelText:state];
    label.font = [UIFont systemFontOfSize:16];
    label.backgroundColor = [UIColor clearColor];
    label.shadowColor     = [UIColor colorWithWhite:0.0 alpha:0.5];
    label.textColor       = [UIColor whiteColor];
    [label sizeToFit];
    return label;
}

-(NSString*) getItineraryTripArrivalLabelText:(OBATripState*)state {
    OBAItineraryV2 * itinerary = state.itinerary;
    NSDate * endTime = itinerary.endTime;
    NSTimeInterval interval = [endTime timeIntervalSinceNow];
    NSInteger mins = interval / 60;
    if( -1 <= mins && mins <= 1 ) {
        return @"Arrives now!";
    }
    else if( 1 < mins && mins <= 50 ) {
        return [NSString stringWithFormat:@"Arrives in %d minutes", mins];
    }
    else if( 50 < mins ) {
        return [NSString stringWithFormat:@"Arrives at %@",[_timeFormatter stringFromDate:endTime]];
    }
    else if( -50 <= mins && mins < -1 ) {
        return [NSString stringWithFormat:@"Arrived %d minutes ago", (-mins)];
    }
    else {
        return [NSString stringWithFormat:@"Arrived at %@",[_timeFormatter stringFromDate:endTime]];
    }
}

-(void) showInfoOverlay:(BOOL)show clear:(BOOL)clear{
    if( show != _infoOverlayVisible ) {
        _infoOverlayVisible = show;
        if( _infoOverlayVisible )
            [self.view addSubview:_infoOverlay];
        else
            [_infoOverlay removeFromSuperview];
    }
    if( clear ) {
        for( UIView * view in _infoOverlay.subviews )
            [view removeFromSuperview];
    }
}

@end


