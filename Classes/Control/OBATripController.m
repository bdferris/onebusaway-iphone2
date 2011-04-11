#import "OBATripController.h"
#import "OBAItinerariesV2.h"
#import "OBAPresentation.h"
#import "OBATripPolyline.h"
#import "OBASphericalGeometryLibrary.h"
#import "SBJSON.h"



@interface OBAItineraryMapping : NSObject {

}

@property (nonatomic,retain) OBAItineraryV2 * fromItinerary;
@property (nonatomic,retain) OBAItineraryV2 * toItinerary;
@property (nonatomic) NSInteger score;

@end

@implementation OBAItineraryMapping

@synthesize fromItinerary;
@synthesize toItinerary;
@synthesize score;

- (void) dealloc {
    self.fromItinerary = nil;
    self.toItinerary = nil;
    [super dealloc];
}

@end



@interface OBATripController (Private)

- (void) refreshLocationForPlace:(OBAPlace*)place;
- (void) refreshTripState;

- (NSArray*) mapOldItineraries:(NSArray*)oldItineraries toNewItineriares:(NSArray*)newItineraries;
- (OBAItineraryV2*) getMappedItinerary:(OBAItineraryV2*)existingItinerary mappings:(NSArray*)mappings;
- (NSInteger) computeMatchScoreForItineraryA:(OBAItineraryV2*)itineraryA itineraryB:(OBAItineraryV2*)itineraryB;

- (void) selectItinerary:(OBAItineraryV2*)itinerary matchPreviousItinerary:(BOOL)matchPreviousItinerary;
- (NSInteger) matchBestIndexForTripState:(OBATripState*)state;
- (NSInteger) computeMatchScoreForTripStateA:(OBATripState*)stateA tripStateB:(OBATripState*)stateB;
- (BOOL) checkEqualA:(NSString*)a b:(NSString*)b;
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

@synthesize query = _query;
@synthesize itineraries = _itineraries;
@synthesize currentItinerary = _currentItinerary;

- (id) init {
    self = [super init];
    if (self) {
        _currentStates = [[NSMutableArray alloc] init];
        _itineraries = [[NSArray alloc] init];
    }
    return self;
}

- (void) dealloc {
    [_currentStates release];
    [_query release];     
    [super dealloc];
}

- (void) planTripWithQuery:(OBATripQuery*)query {
    _query = [NSObject releaseOld:_query retainNew:query];
    _itineraries = [NSObject releaseOld:_itineraries retainNew:nil];
    _currentItinerary = [NSObject releaseOld:_currentItinerary retainNew:nil];
    [_currentStates removeAllObjects];
    _currentStateIndex = -1;
    [self refresh];
}

- (void) selectItinerary:(OBAItineraryV2*)itinerary {
    [self selectItinerary:itinerary matchPreviousItinerary:FALSE];
}

- (void) showItineraries {
    [self.delegate chooseFromItineraries:_itineraries];
}

- (void) refresh {
    
    if( ! _query )
        return;
    
    [self refreshLocationForPlace:_query.placeFrom];
    [self refreshLocationForPlace:_query.placeTo];
    
    CLLocation * from = _query.placeFrom.location;
    CLLocation * to = _query.placeTo.location;  
    
    OBATargetTime * targetTime = _query.time;
    BOOL arriveBy = targetTime.type == OBATargetTimeTypeArriveBy;
    NSDate * t = targetTime.time;
    if( targetTime.type == OBATargetTimeTypeNow )
        t = [NSDate date];
    
    NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
    if( _currentItinerary ) {
        SBJSON * jsonFactory = [[SBJSON alloc] init];
        NSError * error = nil;
        NSString * json =[jsonFactory stringWithObject:_currentItinerary.rawData error:&error];
        if( json )
            [options setObject:json forKey:@"includeSpecificItinerary"];
    }
    [self.modelService planTripFrom:from.coordinate to:to.coordinate time:t arriveBy:arriveBy options:options delegate:self context:nil];
    [options release];
}

- (OBATripState*) tripState {
    if( [_currentStates count] > 0 )
        return [_currentStates objectAtIndex:_currentStateIndex];
    return nil;
}

- (BOOL) hasPreviousState {
    return _currentStateIndex > 0 && [_currentStates count] > 0;
}

- (BOOL) hasCurrentState {
    return [_currentStates count] > 1;
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
    
    // Map from old results to new results
    NSArray * mappings = [self mapOldItineraries:_itineraries toNewItineriares:itineraries.itineraries];

    _itineraries = [NSObject releaseOld:_itineraries retainNew:itineraries.itineraries];
    
    if( _currentItinerary ) {
        OBAItineraryV2 * itinerary = [self getMappedItinerary:_currentItinerary mappings:mappings];
        if( itinerary ) {
            [self selectItinerary:itinerary matchPreviousItinerary:TRUE];
            return;
        }
            
    }    
    
    NSInteger n = [_itineraries count];
    if ( n == 1 || (n > 1 && _query.automaticallyPickBestItinerary) ) {
        [self selectItinerary:[itineraries.itineraries objectAtIndex:0] matchPreviousItinerary:FALSE];
    }
    else {
        [self showItineraries];
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

- (NSArray*) mapOldItineraries:(NSArray*)oldItineraries toNewItineriares:(NSArray*)newItineraries {
    
    
    NSMutableArray * mappings = [[NSMutableArray alloc] init];
    
    for( OBAItineraryV2 * oldItinerary in oldItineraries ) {
        for( OBAItineraryV2 * newItinerary in newItineraries ) {        
            NSInteger score = [self computeMatchScoreForItineraryA:oldItinerary itineraryB:newItinerary];
            if( score > 0 ) {
                OBAItineraryMapping * mapping = [[OBAItineraryMapping alloc] init];
                mapping.fromItinerary = oldItinerary;
                mapping.toItinerary = newItinerary;
                mapping.score = score;
                [mappings addObject:mapping];
                [mapping release];
            }
        }
    }
    
    [mappings sortUsingSelector:@selector(score)];
    
    NSMutableArray * bestMappings = [NSMutableArray array];
    
    while ([mappings count] > 0) {
        OBAItineraryMapping * mapping = [mappings objectAtIndex:([mappings count] - 1)];
        [mapping retain];
        [mappings removeLastObject];
        [bestMappings addObject:mapping];
        [mapping release];

        NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
        NSUInteger index = 0;
        
        for (OBAItineraryMapping * m in mappings) {
            if (m.fromItinerary == mapping.fromItinerary || m.toItinerary == mapping.toItinerary)
                [indices addIndex:index];
            index++;
        }
        
        [mappings removeObjectsAtIndexes:indices];
    }
    
    [mappings release];
    
    return bestMappings;
}

- (OBAItineraryV2*) getMappedItinerary:(OBAItineraryV2*)existingItinerary mappings:(NSArray*)mappings {
    
    for( OBAItineraryMapping * mapping in mappings ) {
        if( mapping.fromItinerary == existingItinerary )
            return mapping.toItinerary;
    }
    
    return nil;
}

- (NSInteger) computeMatchScoreForItineraryA:(OBAItineraryV2*)itineraryA itineraryB:(OBAItineraryV2*)itineraryB {
    
    NSInteger transitLegCountA = 0;
    NSInteger transitLegCountB = 0;
    
    NSInteger score = 0;
    
    for (OBALegV2 * legA in itineraryA.legs ) {
        if( legA.transitLeg )
            transitLegCountA++;
    }
    
    for (OBALegV2 * legB in itineraryB.legs ) {
        if( legB.transitLeg )
            transitLegCountB++;
    }
    
    for (OBALegV2 * legA in itineraryA.legs ) {
        OBATransitLegV2 * transitLegA = legA.transitLeg;
        if (! transitLegA)
            continue;
        for (OBALegV2 * legB in itineraryB.legs ) {
            OBATransitLegV2 * transitLegB = legB.transitLeg;
            if(! transitLegB)
                continue;
            if([transitLegA.tripId isEqualToString:transitLegB.tripId])
                score += 50;
            if( transitLegA.vehicleId && transitLegB.vehicleId && [transitLegA.vehicleId isEqualToString:transitLegB.vehicleId])
                score += 50;
        }
    }
    
    if( transitLegCountA == 0 && transitLegCountB == 0 )
        score += 50;
    
    return score;
}

- (void) selectItinerary:(OBAItineraryV2*)itinerary matchPreviousItinerary:(BOOL)matchPreviousItinerary {
    
    OBATripState * prevState = nil;
    if (matchPreviousItinerary) {
        prevState = [_currentStates objectAtIndex:_currentStateIndex];
        [prevState retain];
    }
    
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
            
            if( index == 0 ) {
                state.startTime = _currentItinerary.startTime;
                BOOL a = _query.time.type == OBATargetTimeTypeNow;
                NSComparisonResult r = [_currentItinerary.startTime compare:_query.time.time];
                BOOL b = r == NSOrderedAscending;
                state.isLateStartTime =  a && b;
                if( state.isLateStartTime )
                    NSLog(@"Late start!");
            }
            
            if( nextLeg && nextLeg.transitLeg ) {
                OBATransitLegV2 * transitLeg = nextLeg.transitLeg;
                if( transitLeg.fromStopId ) {
                    state.walkToStop = transitLeg.fromStop;
                    state.departure = transitLeg;
                }
            }
            
            if( ! state.walkToStop ) {
                state.walkToPlace = _query.placeTo;
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
    
    if( prevState ) {
        _currentStateIndex = [self matchBestIndexForTripState:prevState];
        [prevState release];
        prevState = nil;
    }
    else if ( [_currentStates count ] > 0 && _query.automaticallyPickBestItinerary ) {
        _currentStateIndex = 1;
    }
    
    [self refreshTripState];
}

- (NSInteger) matchBestIndexForTripState:(OBATripState*)state {
    NSInteger bestScore = 0;
    NSInteger bestIndex = 0;
    for (NSUInteger index=0; index<[_currentStates count]; index++) {
        OBATripState * cState = [_currentStates objectAtIndex:index];
        NSInteger score = [self computeMatchScoreForTripStateA:state tripStateB:cState];
        if( score > bestScore ) {
            bestScore = score;
            bestIndex = index;
        }
    }
    
    return bestIndex;
}

- (NSInteger) computeMatchScoreForTripStateA:(OBATripState*)stateA tripStateB:(OBATripState*)stateB {
    NSInteger score = 0;
    
    if( stateA.showTripSummary == stateB.showTripSummary )
        score += 1;
    if( [self checkEqualA:stateA.walkToStop.stopId b:stateB.walkToStop.stopId] )
        score += 1;
    if( stateA.walkToPlace == stateB.walkToPlace )
        score += 1;
    if( [self checkEqualA:stateA.departure.tripId b:stateB.departure.tripId] )
        score += 1;
    if( [self checkEqualA:stateA.ride.tripId b:stateB.ride.tripId] )
        score += 1;
    if( [self checkEqualA:stateA.continuesAs.tripId b:stateB.continuesAs.tripId] )
        score += 1;
    if( [self checkEqualA:stateA.arrival.tripId b:stateB.arrival.tripId] )
        score += 1;
    
    return score;
}

- (BOOL) checkEqualA:(NSString*)a b:(NSString*)b {
    if( a == nil )
        return b == nil;
    else
        return [a isEqualToString:b];
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
    state.placeFrom = _query.placeFrom;
    state.placeTo = _query.placeTo;
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
    [bounds addLocation:_query.placeFrom.location];
    [bounds addLocation:_query.placeTo.location];
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
