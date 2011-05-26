#import "OBAPlacesMapViewController.h"
#import "OBAPlaceAnnotation.h"
#import "OBACoordinateBounds.h"


@implementation OBAPlacesMapViewController

@synthesize target;
@synthesize action;
@synthesize cancelAction;

- (id) initWithPlaces:(NSArray*)places {
    self = [super init];
    if( self ) {
        _places = [places retain];
        self.navigationItem.title = @"Did you mean...";
        self.navigationItem.backBarButtonItem.title = @"Cancel";
    }
    return self;
}

- (void)dealloc {
    [_places release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)loadView {
    
    MKMapView * mapView = [[MKMapView alloc] init];
    mapView.delegate = self;
    self.view = mapView;
    [mapView release];
    
    UIBarButtonItem * cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
    self.navigationItem.rightBarButtonItem = cancelItem;
    [cancelItem release];
}

- (void) viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];
    
    MKMapView * mapView = (MKMapView*) self.view;
    
    OBACoordinateBounds * bounds = [[OBACoordinateBounds alloc] init];
    
    for (OBAPlace * place in _places ) {
        OBAPlaceAnnotation * annotation = [[OBAPlaceAnnotation alloc] initWithPlace:place];
        [mapView addAnnotation:annotation];
        [annotation release];
        
        [bounds addLocation:place.location];
    }
    
    if (! bounds.empty) {
        [mapView setRegion:bounds.region animated:TRUE];
    }
    
    [bounds release];
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id<MKAnnotation>)annotation {    

	if( [annotation isKindOfClass:[OBAPlaceAnnotation class]] ) {
        
        //OBAPlaceAnnotation * placeAnnotation = annotation;
        
		MKPinAnnotationView * view = (MKPinAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"OBAPlaceAnnotation"];
		if( view == nil ) {
			view = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"OBAPlaceAnnotation"] autorelease];
		}

		view.canShowCallout = TRUE;
		view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        view.pinColor = MKPinAnnotationColorGreen;
        
		return view;                                     
    }

    return nil;
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	id<MKAnnotation> annotation = view.annotation;
    if ([annotation isKindOfClass:[OBAPlaceAnnotation class]]) {
        OBAPlaceAnnotation * placeAnnotation = (OBAPlaceAnnotation*) annotation;
        OBAPlace * place = placeAnnotation.place;
        [self dismissModalViewControllerAnimated:TRUE];
        if (self.target && self.action)
            [self.target performSelector:self.action withObject:place];
    }
}

-(IBAction) onCancel:(id)sender {
    [self dismissModalViewControllerAnimated:TRUE];
    if (self.target && self.cancelAction)
        [self.target performSelector:self.cancelAction];

}

@end
