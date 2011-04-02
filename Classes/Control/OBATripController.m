#import "OBATripController.h"
#import "OBAItinerariesV2.h"
#import "OBAPresentation.h"
#import "OBATripPolyline.h"
#import "OBASphericalGeometryLibrary.h"



@interface OBATripController (Private)

- (void) refreshLocationForPlace:(OBAPlace*)place;
- (void) refreshTripState;
- (void) applyItinerary:(OBAItineraryV2*)itinerary;
- (OBATripState*) computeSummaryState;
- (OBATripState*) createTripState;
- (MKCoordinateRegion) computeRegionForItinerary;
- (MKCoordinateRegion) computeRegionForLeg:(OBALegV2*)leg;
- (MKCoordinateRegion) computeRegionForStartOfLeg:(OBALegV2*)leg;
- (MKCoordinateRegion) computeRegionForEndOfLeg:(OBALegV2*)leg;
- (void) computeBounds:(OBACoordinateBounds*)bounds forLeg:(OBALegV2*)leg;

@end


@implementation OBATripController

@synthesize locationManager;
@synthesize modelService;
@synthesize delegate;

@synthesize placeFrom = _placeFrom;
@synthesize placeTo = _placeTo;

- (id) init {
    self = [super init];
    if (self) {
        _currentStates = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc {
    [_currentStates release];
    [super dealloc];
}

- (void) planTripFrom:(OBAPlace*)fromPlace to:(OBAPlace*)toPlace {
    
    _placeFrom = [NSObject releaseOld:_placeFrom retainNew:fromPlace];
    _placeTo = [NSObject releaseOld:_placeTo retainNew:toPlace];
    
    [self refreshLocationForPlace:_placeFrom];
    [self refreshLocationForPlace:_placeTo];

    CLLocation * from = fromPlace.location;
    CLLocation * to = toPlace.location;    
    NSDate * time = [NSDate date];
    
    [self.modelService planTripFrom:from.coordinate to:to.coordinate time:time arriveBy:FALSE options:nil delegate:self context:nil];
}

- (OBATripState*) tripState {
    if( [_currentStates count] > 0 )
        return [_currentStates objectAtIndex:_currentStateIndex];
    return nil;
}

- (BOOL) hasPreviousState {
    return _currentStateIndex > 0 && [_currentStates count] > 0;
}

- (BOOL) hasNextState {
    return _currentStateIndex < [_currentStates count] - 1;
}

- (void) moveToPrevState {
    if( [self hasPreviousState] ) {
        _currentStateIndex--;
        [self refreshTripState];
    }
}

- (void) moveToNextState {
    if( [self hasNextState] ) {
        _currentStateIndex++;
        [self refreshTripState];
    }
}

- (void) moveToCurrentState {
    if( [_currentStates count] > 1) {
        _currentStateIndex = 1;
        [self refreshTripState];
    }
}


#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {

    OBAEntryWithReferencesV2 * entry = obj;
    OBAItinerariesV2 * itineraries = entry.entry;
    if ([itineraries.itineraries count] > 0 ) {
        [self applyItinerary:[[itineraries.itineraries objectAtIndex:0] retain]];
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

- (void) refreshLocationForPlace:(OBAPlace*)place {
    if( place.useCurrentLocation )
        place.location = locationManager.currentLocation;
}

- (void) refreshTripState {
    [self.delegate refreshTripState:[_currentStates objectAtIndex:_currentStateIndex]];
}

- (void) applyItinerary:(OBAItineraryV2*)itinerary {

    _currentItinerary = [NSObject releaseOld:_currentItinerary retainNew:itinerary];
    _currentStateIndex = 0;
    
    [_currentStates removeAllObjects];
    [_currentStates addObject:[self computeSummaryState]];
    
    NSArray * legs = _currentItinerary.legs;
    NSUInteger n = [legs count];
    
    for( NSUInteger index = 0; index < n; index ++ ) {

        OBALegV2 * leg = [legs objectAtIndex:index];
        OBALegV2 * nextLeg = nil;
        if( index + 1 < n )
            nextLeg = [legs objectAtIndex:(index+1)];

        if( [leg.mode isEqualToString:@"walk"] ) {
            
            OBATripState * state = [self createTripState];
            
            if( index == 0 )
                state.startTime = _currentItinerary.startTime;
            
            if( nextLeg && nextLeg.transitLeg ) {
                OBATransitLegV2 * transitLeg = nextLeg.transitLeg;
                if( transitLeg.fromStopId ) {
                    state.walkToStop = transitLeg.fromStop;
                    state.departure = transitLeg;
                }
            }
            
            if( ! state.walkToStop ) {
                state.walkToPlace = self.placeTo;
            }
            
            state.region = [self computeRegionForLeg:leg];
            
            [_currentStates addObject:state];            
        }
        else if ( [leg.mode isEqualToString:@"transit"] ) {
            
            OBATransitLegV2 * transitLeg = leg.transitLeg;
            if( transitLeg.fromStopId ) {
                OBATripState * departureState = [self createTripState];
                departureState.departure = leg.transitLeg;
                departureState.region = [self computeRegionForStartOfLeg:leg];
                [_currentStates addObject:departureState];
            }
            else {
                OBATripState * continuesAsState = [self createTripState];
                continuesAsState.continuesAs = leg.transitLeg;
                continuesAsState.region = [self computeRegionForStartOfLeg:leg];
                [_currentStates addObject:continuesAsState];
            }
            
            OBATripState * rideState = [self createTripState];
            rideState.ride = leg.transitLeg;
            rideState.region = [self computeRegionForLeg:leg];
            [_currentStates addObject:rideState];
            
            if( transitLeg.toStopId ) {
                OBATripState * arrivalState = [self createTripState];
                arrivalState.arrival = leg.transitLeg;
                arrivalState.region = [self computeRegionForEndOfLeg:leg];
                [_currentStates addObject:arrivalState];
            }
        }
    }
    
    [self refreshTripState];
}

- (OBATripState*) computeSummaryState {
    OBATripState * state = [self createTripState];
    state.showTripSummary = TRUE;
    state.startTime = _currentItinerary.startTime;
    state.region = [self computeRegionForItinerary];
    return state;
}

- (OBATripState*) createTripState {
    OBATripState * state = [[[OBATripState alloc] init] autorelease];
    state.placeFrom = self.placeFrom;
    state.placeTo = self.placeTo;
    state.itinerary = _currentItinerary;
    return state;
}
                                
- (MKCoordinateRegion) computeRegionForLeg:(OBALegV2*)leg {
    OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
    [self computeBounds:bounds forLeg:leg];
    return bounds.region;
}

- (MKCoordinateRegion) computeRegionForStartOfLeg:(OBALegV2*)leg {
    OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
    if( leg.transitLeg ) {
        OBATransitLegV2 * transitLeg = leg.transitLeg;
        OBAStopV2 * stop = transitLeg.fromStop;
        if( stop ) {
            [bounds addLat:stop.lat lon:stop.lon];
        }
        if( transitLeg.path ) {
            NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:transitLeg.path];
            if ([points count] > 0)
                [bounds addLocation:[points objectAtIndex:0]];
        }        
    }
    if( [bounds empty] )
        return [self computeRegionForItinerary];
    return bounds.region;
}

- (MKCoordinateRegion) computeRegionForEndOfLeg:(OBALegV2*)leg {
    OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
    if( leg.transitLeg ) {
        OBATransitLegV2 * transitLeg = leg.transitLeg;
        OBAStopV2 * stop = transitLeg.toStop;
        if( stop ) {
            [bounds addLat:stop.lat lon:stop.lon];
        }
        if( transitLeg.path ) {
            NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:transitLeg.path];
            if ([points count] > 0)
                [bounds addLocation:[points objectAtIndex:([points count])-1]];
        }        
    }
    if( [bounds empty] )
        return [self computeRegionForItinerary];
    return bounds.region;
}
         
- (MKCoordinateRegion) computeRegionForItinerary {
    OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
    for( OBALegV2 * leg in _currentItinerary.legs )
        [self computeBounds:bounds forLeg:leg];
    [bounds addLocation:self.placeFrom.location];
    [bounds addLocation:self.placeTo.location];
    return bounds.region;

}

- (void) computeBounds:(OBACoordinateBounds*)bounds forLeg:(OBALegV2*)leg {
    
    if( leg.transitLeg ) {
        OBATransitLegV2 * transitLeg = leg.transitLeg;
        if( transitLeg.path ) {
            NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:transitLeg.path];
            [bounds addLocations:points];
        }
    }
    if ([leg.streetLegs count] > 0 ) {
        for( OBAStreetLegV2 * streetLeg in leg.streetLegs ) {
            if( streetLeg.path ) {
                NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:streetLeg.path];
                [bounds addLocations:points];
            }
        }
    }
}

@end
