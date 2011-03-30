#import "OBATripController.h"
#import "OBAItinerariesV2.h"
#import "OBAPresentation.h"
#import "OBATripPolyline.h"
#import "OBASphericalGeometryLibrary.h"



@interface OBATripController (Private)

- (NSArray*) overlaysForItinerary:(OBAItineraryV2*)itinerary bounds:(OBACoordinateBounds*)bounds;

@end


@implementation OBATripController

@synthesize modelService;
@synthesize delegate;

- (void) planTripFrom:(OBAPlace*)fromPlace to:(OBAPlace*)toPlace {

    CLLocation * from = fromPlace.location;
    CLLocation * to = toPlace.location;    
    NSDate * time = [NSDate date];
    
    [self.modelService planTripFrom:from.coordinate to:to.coordinate time:time arriveBy:FALSE options:nil delegate:self context:nil];
}

- (OBATripState*) tripState {
    OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
    if( ! _currentItinerary )
        return nil;
    OBATripState * state = [[[OBATripState alloc] init] autorelease];
    state.itinerary = _currentItinerary;
    state.overlays = [self overlaysForItinerary:_currentItinerary bounds:bounds];
    state.preferredRegion = bounds.region;
    return state;
}

- (BOOL) hasPreviousState {
    return FALSE;
}

- (BOOL) hasNextState {
    return FALSE;
}

- (void) moveToPrevState {
    
}

- (void) moveToNextState {
    
}

- (void) moveToCurrentState {
    
}


#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {

    OBAEntryWithReferencesV2 * entry = obj;
    OBAItinerariesV2 * itineraries = entry.entry;
    if ([itineraries.itineraries count] > 0 ) {
        _currentItinerary = [[itineraries.itineraries objectAtIndex:0] retain];
        [self.delegate refreshTrip];
    }
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {

}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {

}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    
}

@end



@implementation OBATripController (Private)

- (NSArray*) overlaysForItinerary:(OBAItineraryV2*)itinerary bounds:(OBACoordinateBounds*)bounds {
    
    NSMutableArray * list = [NSMutableArray array];
    for( OBALegV2 * leg in itinerary.legs ) {
        if( leg.transitLeg ) {
            OBATransitLegV2 * transitLeg = leg.transitLeg;
            if( transitLeg.path ) {
                NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:transitLeg.path];
                [bounds addLocations:points];
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
                    [bounds addLocations:points];
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
