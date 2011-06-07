#import "OBATripController.h"
#import "OBAItinerariesV2.h"
#import "OBAPresentation.h"
#import "OBATripPolyline.h"
#import "OBASphericalGeometryLibrary.h"
#import "SBJSON.h"
#import "OBAAlarmState.h"



static const NSString * kCancelAlarm = @"cancelAlarm";
static const NSInteger kRefreshInterval = 30;
static const double kRegionExpansionRatio = 0.1;
static const double kSnapDistanceToStop = 100;
static const NSTimeInterval kExpiredQueryThreshold = 60 * 60;
static const NSInteger kLookaheadTime = 3*60;

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

- (void) clearQueryRequest;

- (void) clearRefreshTimer;
- (void) setRefreshTimer;

- (void) refreshLocationForPlace:(OBAPlace*)place;
- (void) refreshTripState;

- (void) clearSelectedItinerary;

- (BOOL) isQueryExpired;

- (void) getAllDeparturesAtStop:(NSString*)stopId forTripState:(OBATripState*)tripState;
- (void) getAllArrivalsAtStop:(NSString*)stopId forTripState:(OBATripState*)tripState;

- (NSInteger) matchBestIndexForTripState:(OBATripState*)state;
- (NSInteger) computeMatchScoreForTripStateA:(OBATripState*)stateA tripStateB:(OBATripState*)stateB;
- (BOOL) checkEqualA:(NSString*)a b:(NSString*)b;
- (OBATripState*) computeSummaryState;
- (OBATripState*) createTripStateForType:(OBATripStateType)type;

- (OBAAlarmRef*) getAlarmRefForType:(OBAAlarmType)alarmType tripState:(OBATripState*)tripState;
- (OBAAlarmState*) getAlarmStateForRef:(OBAAlarmRef*)alarmRef;
- (OBAAlarmState*) createAlarmWithRef:(OBAAlarmRef*)alarmRef tripState:(OBATripState*)tripState alarmTimeOffset:(NSInteger)alarmTimeOffset;
- (void) registerAlarm:(OBAAlarmState*)alarmState;
- (void) updateAlarmsWithMatchPreviousItinerary:(BOOL)matchPreviousItinerary;
- (BOOL) hasStartTripAlarmMatch:(OBAAlarmRef*)alarmRef;
- (BOOL) hasDepartureAlarmMatch:(OBAAlarmRef*)alarmRef;
- (BOOL) hasArrivalAlarmMatch:(OBAAlarmRef*)alarmRef;
- (void) cancelAlarm:(OBAAlarmState*)alarmState;
- (void) cancelAlarms:(NSArray*)alarms;
- (void) cancelAllAlarms;

- (void)alarmRequestDidFinishWithAlarm:(OBAAlarmState*)alarmState alarmId:(NSString*)alarmId;

- (MKCoordinateRegion) computeRegionForQuery;
- (MKCoordinateRegion) computeRegionForItinerary;
- (MKCoordinateRegion) computeRegionForLeg:(OBALegV2*)leg;
- (MKCoordinateRegion) computeRegionForStartOfLeg:(OBALegV2*)leg;
- (MKCoordinateRegion) computeRegionForEndOfLeg:(OBALegV2*)leg;
- (void) computeBounds:(OBACoordinateBounds*)bounds forLeg:(OBALegV2*)leg;

@end


@implementation OBATripController

@synthesize locationManager;
@synthesize modelService;
@synthesize modelDao;

@synthesize queryIndex = _queryIndex;
@synthesize query = _query;
@synthesize lastUpdate = _lastUpdate;
@synthesize itineraries = _itineraries;
@synthesize currentItinerary = _currentItinerary;

- (id) init {
    self = [super init];
    if (self) {
        _currentStates = [[NSMutableArray alloc] init];
        _itineraries = [[NSArray alloc] init];
        _currentAlarms = [[NSMutableArray alloc] init];
        _queryIndex = -1;
        _currentStateIndex = -1;
    }
    return self;
}

- (void) dealloc {
    [self clearQueryRequest];
    [self clearRefreshTimer];
    [_currentStates release];
    [_itineraries release];
    [_currentAlarms release];
    [_query release];     
    [super dealloc];
}

- (id<OBATripControllerDelegate>) delegate {
    return _delegate;
}

- (void) setDelegate:(id<OBATripControllerDelegate>)delegate {
    
    _delegate = [NSObject releaseOld:_delegate retainNew:delegate];

    if( _delegate ) {
        // We have an active delegate, so start refreshing as appropriate
        if (_currentItinerary) {
            NSTimeInterval interval = [_lastUpdate timeIntervalSinceNow];

            // Only kick off a direct refresh if it's been a while since our last refresh            
            if( -interval >= kRefreshInterval ) {
                [self refresh];
            }
            else {
                [self setRefreshTimer];
            }
        }
            
    }
    else {
        /**
         * We don't refresh when no delegate is listening
         */
        [self clearRefreshTimer];
    }
    
    [self refreshTripState];
}

- (void) planTripWithQuery:(OBATripQuery*)query {
    
    [self clearQueryRequest];
    [self clearRefreshTimer];
    _lastUpdate = [NSObject releaseOld:_lastUpdate retainNew:nil];

    [self.modelDao addRecentPlace:query.placeFrom];
    [self.modelDao addRecentPlace:query.placeTo];
    
    _queryIndex++;
    
    _query = [NSObject releaseOld:_query retainNew:query];
    _itineraries = [NSObject releaseOld:_itineraries retainNew:nil];
    _currentItinerary = [NSObject releaseOld:_currentItinerary retainNew:nil];
    _currentItineraryIndex = NSNotFound;
    [_currentStates removeAllObjects];
    _currentStateIndex = -1;

    [self cancelAllAlarms];
    [self refreshTripState];
    [self refresh];
}

- (void) clearQuery {
    [self clearQueryRequest];
    [self clearRefreshTimer];
    _lastUpdate = [NSObject releaseOld:_lastUpdate retainNew:nil];
    
}

- (void) selectItinerary:(OBAItineraryV2*)itinerary {
    [self selectItinerary:itinerary matchPreviousItinerary:FALSE];
}

- (void) selectItinerary:(OBAItineraryV2*)itinerary matchPreviousItinerary:(BOOL)matchPreviousItinerary {
    
    OBATripState * prevState = nil;
    if (matchPreviousItinerary) {
        if (_currentStateIndex < 0 || _currentStateIndex >= [_currentStates count] )
            NSLog(@"bad: %d", _currentStateIndex);
        prevState = [_currentStates objectAtIndex:_currentStateIndex];
        [prevState retain];
    }
    
    _currentItinerary = [NSObject releaseOld:_currentItinerary retainNew:itinerary];
    _currentItineraryIndex = [_itineraries indexOfObject:itinerary];
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
            
            /**
             * If it's the first leg of the trip, our next leg is transit, and we're close
             * to the departure stop, we skip the walking step such that the UI jumps straight
             * to the stop.
             */
            if (index == 0 && nextLeg && nextLeg.transitLeg && leg.distance < kSnapDistanceToStop) {
                continue;
            }
            
            OBATripState * state = [self createTripStateForType:OBATripStateTypeWalk];
            
            if( index == 0 ) {
                state.showStartTime = TRUE;
                BOOL a = _query.time.type == OBATargetTimeTypeNow;
                NSDate * startTime = _currentItinerary.startTime;
                NSDate * queryTime = [NSDate date];
                NSComparisonResult r = [startTime compare:queryTime];
                BOOL b = (r == NSOrderedAscending);
                state.isLateStartTime =  a && b;
                if( state.isLateStartTime )
                    NSLog(@"Late start!");
            }
            
            if( nextLeg && nextLeg.transitLeg ) {
                OBATransitLegV2 * transitLeg = nextLeg.transitLeg;
                if( transitLeg.fromStopId ) {
                    state.walkToStop = transitLeg.fromStop;
                    state.departures = [NSArray arrayWithObject:transitLeg];
                    state.departureItineraries = [NSArray arrayWithObject:itinerary];
                    state.selectedDepartureIndex = 0;
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
                OBATripState * departureState = [self createTripStateForType:OBATripStateTypeDepartures];
                departureState.stop = transitLeg.fromStop;
                [self getAllDeparturesAtStop:transitLeg.fromStopId forTripState:departureState];
                departureState.selectedDepartureIndex = [departureState.departures indexOfObject:transitLeg];
                departureState.region = [self computeRegionForStartOfLeg:leg];
                [_currentStates addObject:departureState];
            }
            else {
                OBATripState * continuesAsState = [self createTripStateForType:OBATripStateTypeContinueAs];
                continuesAsState.continuesAs = leg.transitLeg;
                continuesAsState.region = [self computeRegionForStartOfLeg:leg];
                [_currentStates addObject:continuesAsState];
            }
            
            OBATripState * rideState = [self createTripStateForType:OBATripStateTypeRide];
            rideState.ride = leg.transitLeg;
            rideState.region = [self computeRegionForLeg:leg];
            [_currentStates addObject:rideState];
            
            if( transitLeg.toStopId ) {
                OBATripState * arrivalState = [self createTripStateForType:OBATripStateTypeArrivals];
                arrivalState.stop = transitLeg.toStop;
                [self getAllArrivalsAtStop:transitLeg.toStopId forTripState:arrivalState];
                arrivalState.selectedArrivalIndex = [arrivalState.arrivals indexOfObject:transitLeg];
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
    /*
    else if ( [_currentStates count ] > 0 && _query.automaticallyPickBestItinerary ) {
        _currentStateIndex = 1;
    }
    */
    
    [self refreshTripState];
    [self updateAlarmsWithMatchPreviousItinerary:matchPreviousItinerary];
}

- (BOOL) isRefreshingItineraries {
    return _queryRequest != nil;
}

- (void) refresh {
    
    [self clearRefreshTimer];
    [self clearQueryRequest];
    
    if( ! _query )
        return;
    
    if ([self isQueryExpired]) {
        [self clearQuery];
        return;
    }
    
    if([self.delegate respondsToSelector:@selector(refreshingItineraries)])
        [self.delegate refreshingItineraries];
    
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
            [options setObject:json forKey:@"includeSelectedItinerary"];
        [jsonFactory release];         
    }
    
    [options setObject:[NSString stringWithFormat:@"%d",kLookaheadTime] forKey:@"lookaheadTime"];
    
    OBATripQueryOptimizeForType optimizeFor = _query.optimizeFor;
    switch (optimizeFor) {
        case OBATripQueryOptimizeForTypeMinimizeTime:
            [options setObject:@"min_time" forKey:@"optimizeFor"];
            break;
        case OBATripQueryOptimizeForTypeMinimizeTransfers:
            [options setObject:@"min_transfers" forKey:@"optimizeFor"];
            break;
        case OBATripQueryOptimizeForTypeMinimizeWalking:
            [options setObject:@"min_walking" forKey:@"optimizeFor"];
            break;
        default:
            break;
    }
    _queryRequest = [[self.modelService planTripFrom:from.coordinate to:to.coordinate time:t arriveBy:arriveBy options:options delegate:self context:[NSNumber numberWithInt:_queryIndex]] retain];
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
    return [_currentStates count] > 0;
}

- (BOOL) hasNextState {
    return 0 <= _currentStateIndex && _currentStateIndex < [_currentStates count] - 1;
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
    NSUInteger c = [_currentStates count];
    if (c == 0)
        return;
    _currentStateIndex = 0;
    if( c > 1) {
        _currentStateIndex = 1;
    }
    [self refreshTripState];
}

- (BOOL) isAlarmEnabledForType:(OBAAlarmType)alarmType tripState:(OBATripState*)tripState {
    OBAAlarmRef * alarmRef = [self getAlarmRefForType:alarmType tripState:tripState];
    OBAAlarmState * alarmState = [self getAlarmStateForRef:alarmRef];
    return alarmState != nil;
}

- (void) updateAlarm:(BOOL)enabled withType:(OBAAlarmType)alarmType tripState:(OBATripState*)tripState alarmTimeOffset:(NSInteger)alarmTimeOffset {

    OBAAlarmRef * alarmRef = [self getAlarmRefForType:alarmType tripState:tripState];
    if (!alarmRef)
        return;

    if( enabled ) {
        OBAAlarmState * alarmState = [self getAlarmStateForRef:alarmRef];
        // You can't update an existing alarm
        if (! alarmState) {
            OBAAlarmState * alarmState = [self createAlarmWithRef:alarmRef tripState:tripState alarmTimeOffset:alarmTimeOffset];
            [_currentAlarms addObject:alarmState];
            [self registerAlarm:alarmState];
        }
    }
    else {
        OBAAlarmState * alarmState = [self getAlarmStateForRef:alarmRef];
        if( alarmState )
            [self cancelAlarm:alarmState];        
    }
}

- (NSInteger) getAlarmTimeOffsetForType:(OBAAlarmType)alarmType tripState:(OBATripState*)tripState {
    
    OBAAlarmRef * alarmRef = [self getAlarmRefForType:alarmType tripState:tripState];
    
    if (alarmRef) {
        OBAAlarmState * alarmState = [self getAlarmStateForRef:alarmRef];
        if( alarmState )
            return alarmState.userAlarmTimeOffset;
    }

    return 60;
}

- (void) handleAlarm:(NSString*)alarmId {
    NSMutableIndexSet * indexSet = [NSMutableIndexSet indexSet];
    NSUInteger index = 0;
    for( OBAAlarmState * as in _currentAlarms ) {
        if( [alarmId isEqualToString:as.alarmId] )
            [indexSet addIndex:index];
        index++;
    }
    [_currentAlarms removeObjectsAtIndexes:indexSet];
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    
    if( context == kCancelAlarm ) {
        return;
    }
    
    if( [context isKindOfClass:[OBAAlarmState class]] ) {
        [self alarmRequestDidFinishWithAlarm:context alarmId:obj];
        return;
    }
    
    OBAEntryWithReferencesV2 * entry = obj;
    OBAItinerariesV2 * itineraries = entry.entry;
    
    _itineraries = [NSObject releaseOld:_itineraries retainNew:itineraries.itineraries];
    _lastUpdate = [NSObject releaseOld:_lastUpdate retainNew:[NSDate date]];
    
    if ([self.delegate respondsToSelector:@selector(refreshingItinerariesCompleted)]) {
        [self.delegate refreshingItinerariesCompleted];
    }
    
    for (OBAItineraryV2 * itinerary in _itineraries ) {
        if( itinerary.selected ) { 
            [self selectItinerary:itinerary matchPreviousItinerary:TRUE];
            [self clearQueryRequest];
            [self setRefreshTimer];
            return;
        }
    }
    
    if( [_itineraries count] > 0 ) {
        
        NSInteger toSelect = 0;

        for (NSUInteger index=0; index < [_itineraries count]; index++) {
            OBAItineraryV2 * itinerary = [_itineraries objectAtIndex:index];
            NSTimeInterval interval = [itinerary.startTime timeIntervalSinceDate:_lastUpdate];
            if( interval > -30 ) {
                toSelect = index;
                break;
            }
        }
        
        [self selectItinerary:[itineraries.itineraries objectAtIndex:toSelect] matchPreviousItinerary:FALSE];
        [self setRefreshTimer];
    }
    else {
        [self clearSelectedItinerary];
    }
    
    [self clearQueryRequest];
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {

    if( context == kCancelAlarm ) {
        return;
    }
    
    if( [context isKindOfClass:[OBAAlarmState class]] ) {
        return;
    }
    
    [self clearQueryRequest];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
    
    if( context == kCancelAlarm ) {
        return;
    }
    
    if( [context isKindOfClass:[OBAAlarmState class]] ) {
        return;
    }
    
    [self clearQueryRequest];

    if([self.delegate respondsToSelector:@selector(refreshingItinerariesFailed:)])
       [self.delegate refreshingItinerariesFailed:error];
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    
}

@end



@implementation OBATripController (Private)

- (void) clearQueryRequest {
    if (_queryRequest) {
        [_queryRequest cancel];
        [_queryRequest release];
        _queryRequest = nil;
    }
}

- (void) clearRefreshTimer {
    [_refreshTimer invalidate];
    [_refreshTimer release];
    _refreshTimer = nil;
}

- (void) setRefreshTimer {
    NSTimeInterval interval = kRefreshInterval;
    _refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refresh) userInfo:nil repeats:FALSE] retain];
}

- (void) refreshLocationForPlace:(OBAPlace*)place {
    if( place.isCurrentLocation )
        place.location = locationManager.currentLocation;
}

- (void) refreshTripState {
    if ([self.delegate respondsToSelector:@selector(refreshTripState:)]) {
        OBATripState * state = nil;
        if ([_currentStates count] > 0)
            state = [_currentStates objectAtIndex:_currentStateIndex];
        [self.delegate refreshTripState:state];
    }
}

- (void) clearSelectedItinerary {
    _currentItinerary = [NSObject releaseOld:_currentItinerary retainNew:nil];
    _currentItineraryIndex = NSNotFound;
    _currentStateIndex = -1;
    
    [_currentStates removeAllObjects];
    
    OBATripState * state = [self createTripStateForType:OBATripStateTypeItineraries];
    state.region = [self computeRegionForQuery];
    [_currentStates addObject:state];
    
    [self refreshTripState];
}

- (BOOL) isQueryExpired {
    if (! _currentItinerary)
        return FALSE;
    
    NSTimeInterval interval = - [_currentItinerary.endTime timeIntervalSinceNow];
    return interval > kExpiredQueryThreshold;
}

- (void) getAllDeparturesAtStop:(NSString*)stopId forTripState:(OBATripState*)tripState {
    NSMutableArray * departures = [NSMutableArray array];
    NSMutableArray * itineraries = [NSMutableArray array];
    for (OBAItineraryV2 * itinerary in _itineraries ) {
        for (OBALegV2 * leg in itinerary.legs ) {
            if ([leg.mode isEqualToString:@"transit"]) {
                OBATransitLegV2 * transitLeg = leg.transitLeg;
                if ([stopId isEqualToString:transitLeg.fromStopId]) {
                    [departures addObject:transitLeg];
                    [itineraries addObject:itinerary];
                }
            }
        }
    }
    tripState.departures = departures;
    tripState.departureItineraries = itineraries;
}

- (void) getAllArrivalsAtStop:(NSString*)stopId forTripState:(OBATripState*)tripState {
    NSMutableArray * arrivals = [NSMutableArray array];
    NSMutableArray * itineraries = [NSMutableArray array];
    for (OBAItineraryV2 * itinerary in _itineraries ) {
        for (OBALegV2 * leg in itinerary.legs ) {
            if ([leg.mode isEqualToString:@"transit"]) {
                OBATransitLegV2 * transitLeg = leg.transitLeg;
                if ([stopId isEqualToString:transitLeg.toStopId]) {
                    [arrivals addObject:transitLeg];
                    [itineraries addObject:itinerary];
                }
            }
        }
    }
    tripState.arrivals = arrivals;
    tripState.arrivalItineraries = itineraries;
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
    
    if (stateA.type != stateB.type)
        return 0;
    
    NSInteger score = 0;
    
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
    OBATripState * state = [self createTripStateForType:OBATripStateTypeItineraries];
    state.itineraries = _itineraries;
    state.selectedItineraryIndex = _currentItineraryIndex;
    state.region = [self computeRegionForItinerary];
    return state;
}

- (OBATripState*) createTripStateForType:(OBATripStateType)type {
    OBATripState * state = [[[OBATripState alloc] init] autorelease];
    state.placeFrom = _query.placeFrom;
    state.placeTo = _query.placeTo;
    state.itinerary = _currentItinerary;
    state.type = type;
    return state;
}
                                
- (MKCoordinateRegion) computeRegionForLeg:(OBALegV2*)leg {
    OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
    [self computeBounds:bounds forLeg:leg];
    [bounds expandByRatio:kRegionExpansionRatio]; 
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
    [bounds expandByRatio:kRegionExpansionRatio];
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
    [bounds expandByRatio:kRegionExpansionRatio];
    return bounds.region;
}
                                      
- (OBAAlarmRef*) getAlarmRefForType:(OBAAlarmType)alarmType tripState:(OBATripState*)tripState {

    switch (alarmType) {
        case OBAAlarmTypeStart: {
            OBAItineraryV2 * itinerary = tripState.itinerary;
            OBALegV2 * leg = [itinerary firstTransitLeg];
            if( leg ) {
                OBATransitLegV2 * transitLeg = leg.transitLeg;
                return [[[OBAAlarmRef alloc] initWithType:alarmType instanceRef:transitLeg.departureInstanceRef] autorelease];
            } 
            
            return nil;
        }
        case OBAAlarmTypeDeparture: {
            
            OBATransitLegV2 * departure = [tripState.departures objectAtIndex:tripState.selectedDepartureIndex];
            return [[[OBAAlarmRef alloc] initWithType:alarmType instanceRef:departure.departureInstanceRef] autorelease];
        }
        case OBAAlarmTypeArrival: {
            OBATransitLegV2 * arrival = [tripState.arrivals objectAtIndex:tripState.selectedArrivalIndex];
            return [[[OBAAlarmRef alloc] initWithType:alarmType instanceRef:arrival.arrivalInstanceRef] autorelease];
        }
        default:
            break;
    }
    
    return nil;
}

- (OBAAlarmState*) getAlarmStateForRef:(OBAAlarmRef*)alarmRef {
    
    for( OBAAlarmState * alarmState in _currentAlarms ) {
        if( [alarmState.alarmRef isEqualToAlarmRef:alarmRef] )
            return alarmState;
    }
    
    return nil;
}

- (OBAAlarmState*) createAlarmWithRef:(OBAAlarmRef*)alarmRef tripState:(OBATripState*)tripState alarmTimeOffset:(NSInteger)alarmTimeOffset {
    
    OBAAlarmState * alarmState = [[[OBAAlarmState alloc] initWithAlarmRef:alarmRef] autorelease];
    alarmState.userAlarmTimeOffset = alarmTimeOffset;
    
    NSMutableDictionary * notificationOptions = [[NSMutableDictionary alloc] init];
    alarmState.notificationOptions = notificationOptions;
    
    [notificationOptions setObject:@"default" forKey:@"sound"];
    
#ifdef APS_ENVIRONMENT_SANDBOX
    NSLog(@"Using the sandbox push notification server");
    [notificationOptions setObject:@"false" forKey:@"production"];
#else
    NSLog(@"Using the production push notification server");    
    [notificationOptions setObject:@"true" forKey:@"production"];
#endif
    
    switch (alarmRef.alarmType) {
        case OBAAlarmTypeStart:
            [notificationOptions setObject:@"Time to start your trip!" forKey:@"alertBody"];
            break;
        case OBAAlarmTypeDeparture:
            [notificationOptions setObject:@"Your departure is coming up!" forKey:@"alertBody"];
            break;
        case OBAAlarmTypeArrival:
            [notificationOptions setObject:@"Your arrival is coming up!" forKey:@"alertBody"];
            break;
        default:
            break;
    }
    
    if( alarmRef.alarmType == OBAAlarmTypeStart ) {
        OBAItineraryV2 * itinerary = tripState.itinerary;
        OBALegV2 * leg = [itinerary firstTransitLeg];
        if( leg ) {
            NSDate * startTime = itinerary.startTime;
            NSDate * legTime = leg.startTime;
            NSTimeInterval interval = [legTime timeIntervalSinceDate:startTime];
            alarmState.alarmTimeOffset = interval;
        }        
    }
    
    [notificationOptions release];
    
    return alarmState;
}

- (void) registerAlarm:(OBAAlarmState*)alarmState {
    
    if( alarmState.alarmId )
        return;
    
    OBAAlarmRef * alarmRef = alarmState.alarmRef;
    OBAArrivalAndDepartureInstanceRef * ref = alarmRef.instanceRef;
    BOOL onArrival = alarmRef.alarmType == OBAAlarmTypeArrival;
    NSInteger alarmTimeOffset = alarmState.alarmTimeOffset + alarmState.userAlarmTimeOffset;
    NSDictionary * notificationOptions = alarmState.notificationOptions;
    
    [self.modelService registerAlarmForArrivalAndDepartureAtStop:ref onArrival:onArrival alarmTimeOffset:alarmTimeOffset notificationOptions:notificationOptions withDelegate:self withContext:alarmState];
}

- (void) updateAlarmsWithMatchPreviousItinerary:(BOOL)matchPreviousItinerary {

    NSMutableArray * alarmsToKeep = [[NSMutableArray alloc] init];
    NSMutableArray * alarmsToCancel = [[NSMutableArray alloc] init];

    if (matchPreviousItinerary && _currentItinerary) {
        for( OBAAlarmState * alarmState in _currentAlarms ) {
            
            BOOL keepAlarm = FALSE;
            switch (alarmState.alarmRef.alarmType) {
                case OBAAlarmTypeStart:
                    keepAlarm = [self hasStartTripAlarmMatch:alarmState.alarmRef];
                    break;
                case OBAAlarmTypeDeparture:
                    keepAlarm = [self hasDepartureAlarmMatch:alarmState.alarmRef];
                    break;
                case OBAAlarmTypeArrival:
                    keepAlarm = [self hasArrivalAlarmMatch:alarmState.alarmRef];
                    break;
                default:
                    break;
            }
        
            if (keepAlarm) {
                [alarmsToKeep addObject:alarmState];
            }
            else {
                [alarmsToCancel addObject:alarmState];
            }
        }        
    }
    else {
        [alarmsToCancel addObjectsFromArray:_currentAlarms];
    }
    
    if ([alarmsToCancel count] > 0 ) {
        [self cancelAlarms:alarmsToCancel];
    }
    
    [_currentAlarms removeAllObjects];
    [_currentAlarms addObjectsFromArray:alarmsToKeep];
    
    [alarmsToKeep release];
    [alarmsToCancel release];
}

- (BOOL) hasStartTripAlarmMatch:(OBAAlarmRef*)alarmRef {
    return [self hasDepartureAlarmMatch:alarmRef];
}

- (BOOL) hasDepartureAlarmMatch:(OBAAlarmRef*)alarmRef {
    for (OBALegV2 * leg in _currentItinerary.legs) {
        if (!leg.transitLeg)
            continue;
        OBATransitLegV2 * transitLeg = leg.transitLeg;
        if (!transitLeg.fromStop)
            continue;
        if ([alarmRef.instanceRef isEqualWithOptionalVehicleId:transitLeg.departureInstanceRef])
            return TRUE;
    }
    return FALSE;
}

- (BOOL) hasArrivalAlarmMatch:(OBAAlarmRef*)alarmRef {
    for (OBALegV2 * leg in _currentItinerary.legs) {
        if (!leg.transitLeg)
            continue;
        OBATransitLegV2 * transitLeg = leg.transitLeg;
        if (!transitLeg.toStop)
            continue;
        if ([alarmRef.instanceRef isEqualWithOptionalVehicleId:transitLeg.arrivalInstanceRef])
            return TRUE;
    }
    return FALSE;
}

- (void) cancelAlarm:(OBAAlarmState*)alarmState {
    
    if( alarmState.alarmId ) {
        [self.modelService cancelAlarmWithId:alarmState.alarmId withDelegate:self withContext:kCancelAlarm];
    }
    
    [_currentAlarms removeObject:alarmState];
}

- (void) cancelAlarms:(NSArray*)alarms {
    NSMutableArray * alarmIds = [[NSMutableArray alloc] init];
    
    for( OBAAlarmState * alarmState in alarms ) {
        if( alarmState.alarmId ) {
            [alarmIds addObject:alarmState.alarmId];
        }
    }
    
    if ([alarmIds count] > 0 ) {
        [self.modelService cancelAlarmsWithIds:alarmIds withDelegate:self withContext:kCancelAlarm];
    }
    
    [alarmIds release];
}

- (void) cancelAllAlarms {
    [self cancelAlarms:_currentAlarms];
    [_currentAlarms removeAllObjects];
}

- (void)alarmRequestDidFinishWithAlarm:(OBAAlarmState*)alarmState alarmId:(NSString*)alarmId {
    alarmState.alarmId = alarmId;
}

- (MKCoordinateRegion) computeRegionForQuery {
    OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
    [bounds addLocation:_query.placeFrom.location];
    [bounds addLocation:_query.placeTo.location];
    [bounds expandByRatio:kRegionExpansionRatio];
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
