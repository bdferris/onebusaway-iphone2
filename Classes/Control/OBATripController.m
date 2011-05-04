#import "OBATripController.h"
#import "OBAItinerariesV2.h"
#import "OBAPresentation.h"
#import "OBATripPolyline.h"
#import "OBASphericalGeometryLibrary.h"
#import "SBJSON.h"
#import "OBAAlarmState.h"



static const NSString * kCancelAlarm = @"cancelAlarm";

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

- (void) clearRefreshTimer;
- (void) setRefreshTimer;

- (void) refreshLocationForPlace:(OBAPlace*)place;
- (void) refreshTripState;

- (void) selectItinerary:(OBAItineraryV2*)itinerary matchPreviousItinerary:(BOOL)matchPreviousItinerary;
- (NSInteger) matchBestIndexForTripState:(OBATripState*)state;
- (NSInteger) computeMatchScoreForTripStateA:(OBATripState*)stateA tripStateB:(OBATripState*)stateB;
- (BOOL) checkEqualA:(NSString*)a b:(NSString*)b;
- (OBATripState*) computeSummaryState;
- (OBATripState*) createTripState;

- (OBAAlarmState*) getAlarmStateForTripState:(OBATripState*)tripState create:(BOOL)create;
- (void) populateAlarmState:(OBAAlarmState*)alarmState;
- (void) registerAlarm:(OBAAlarmState*)alarmState;
- (void) updateAlarmsWithMatchPreviousItinerary:(BOOL)matchPreviousItinerary;
- (void) cancelAlarm:(OBAAlarmState*)alarmState;
- (void) cancelAlarms:(NSArray*)alarms;
- (void) cancelAllAlarms;

- (void)alarmRequestDidFinishWithAlarm:(OBAAlarmState*)alarmState alarmId:(NSString*)alarmId;

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
@synthesize delegate;

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
    }
    return self;
}

- (void) dealloc {
    [_currentStates release];
    [_itineraries release];
    [_currentAlarms release];
    [_query release];     
    [super dealloc];
}

- (void) planTripWithQuery:(OBATripQuery*)query {
    
    [self clearRefreshTimer];

    [self.modelDao addRecentPlace:query.placeFrom];
    [self.modelDao addRecentPlace:query.placeTo];
    
    _query = [NSObject releaseOld:_query retainNew:query];
    _itineraries = [NSObject releaseOld:_itineraries retainNew:nil];
    _currentItinerary = [NSObject releaseOld:_currentItinerary retainNew:nil];
    [_currentStates removeAllObjects];
    _currentStateIndex = -1;
    [self refresh];
    [self cancelAllAlarms];
}

- (void) selectItinerary:(OBAItineraryV2*)itinerary {
    [self selectItinerary:itinerary matchPreviousItinerary:FALSE];
}

- (void) showItineraries {
    if ([self.delegate respondsToSelector:@selector(chooseFromItineraries:)]) {
        [self.delegate chooseFromItineraries:_itineraries];
    }
}

- (void) refresh {
    
    [self clearRefreshTimer];
    
    if( ! _query )
        return;
    
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

- (void) updateAlarm:(BOOL)enabled forTripState:(OBATripState*)tripState alarmTimeOffset:(NSInteger)alarmTimeOffset {
    if( enabled ) {
        OBAAlarmState * alarmState = [self getAlarmStateForTripState:tripState create:TRUE];
        alarmState.alarmTimeOffset = alarmTimeOffset;
        [self registerAlarm:alarmState];
    }
    else {
        OBAAlarmState * alarmState = [self getAlarmStateForTripState:tripState create:FALSE];
        if( alarmState )
            [self cancelAlarm:alarmState];        
    }
}

- (BOOL) isAlarmEnabledForTripState:(OBATripState*)tripState {
    OBAAlarmState * alarmState = [self getAlarmStateForTripState:tripState create:FALSE];
    return alarmState != nil;
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
    
    if ([self.delegate respondsToSelector:@selector(refreshingItinerariesCompleted)]) {
        [self.delegate refreshingItinerariesCompleted];
    }

    OBAEntryWithReferencesV2 * entry = obj;
    OBAItinerariesV2 * itineraries = entry.entry;
    
    _itineraries = [NSObject releaseOld:_itineraries retainNew:itineraries.itineraries];
    _lastUpdate = [NSObject releaseOld:_lastUpdate retainNew:[NSDate date]];
    
    for (OBAItineraryV2 * itinerary in _itineraries ) {
        if( itinerary.selected ) { 
            [self selectItinerary:itinerary matchPreviousItinerary:TRUE];
            [self setRefreshTimer];
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

    [self setRefreshTimer];
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {

    if( context == kCancelAlarm ) {
        return;
    }
    
    if( [context isKindOfClass:[OBAAlarmState class]] ) {
        return;
    }
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
    
    if( context == kCancelAlarm ) {
        return;
    }
    
    if( [context isKindOfClass:[OBAAlarmState class]] ) {
        return;
    }

    if([self.delegate respondsToSelector:@selector(refreshingItinerariesFailed:)])
       [self.delegate refreshingItinerariesFailed:error];
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    
}

@end



@implementation OBATripController (Private)

- (void) clearRefreshTimer {
    [_refreshTimer invalidate];
    [_refreshTimer release];
    _refreshTimer = nil;
}

- (void) setRefreshTimer {
    NSTimeInterval interval = 30;
    _refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refresh) userInfo:nil repeats:FALSE] retain];
}

- (void) refreshLocationForPlace:(OBAPlace*)place {
    if( place.useCurrentLocation )
        place.location = locationManager.currentLocation;
}

- (void) refreshTripState {
    if ([self.delegate respondsToSelector:@selector(refreshTripState:)]) {
        [self.delegate refreshTripState:[_currentStates objectAtIndex:_currentStateIndex]];
    }
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
    [self updateAlarmsWithMatchPreviousItinerary:matchPreviousItinerary];
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

- (OBAAlarmState*) getAlarmStateForTripState:(OBATripState*)tripState create:(BOOL)create {

    for( OBAAlarmState * alarmState in _currentAlarms ) {
        if( alarmState.tripState == tripState )
            return alarmState;
    }
    
    if( create ) {
        OBAAlarmState * alarmState = [[[OBAAlarmState alloc] init] autorelease];
        alarmState.tripState = tripState;
        [self populateAlarmState:alarmState];        
        [_currentAlarms addObject:alarmState];
        return alarmState;
    }
    
    return nil;
}

- (void) populateAlarmState:(OBAAlarmState*)alarmState {
    
    OBATripState * tripState = alarmState.tripState;

    if( tripState.startTime ) {
        OBAItineraryV2 * itinerary = tripState.itinerary;
        OBALegV2 * leg = [itinerary firstTransitLeg];
        if( leg ) {
            OBATransitLegV2 * transitLeg = leg.transitLeg;
            NSDate * startTime = itinerary.startTime;
            NSDate * legTime = leg.startTime;
            NSTimeInterval interval = [legTime timeIntervalSinceDate:startTime];
            alarmState.instanceRef = transitLeg.departureInstanceRef;
            alarmState.onArrival = FALSE;
            alarmState.alarmTimeOffset += interval;
            alarmState.notificationOptions = [NSDictionary dictionaryWithObject:@"Time to start your trip!" forKey:@"alertBody"];
        }        
    }
    else if( tripState.departure ) {
        OBATransitLegV2 * departure = tripState.departure;
        alarmState.instanceRef = departure.departureInstanceRef;
        alarmState.onArrival = FALSE;
        alarmState.notificationOptions = [NSDictionary dictionaryWithObject:@"Your departure is coming up!" forKey:@"alertBody"];
    }
    else if( tripState.arrival ) {
        OBATransitLegV2 * arrival = tripState.arrival;
        alarmState.instanceRef = arrival.arrivalInstanceRef;
        alarmState.onArrival = TRUE;
        alarmState.notificationOptions = [NSDictionary dictionaryWithObject:@"Your arrival is coming up!" forKey:@"alertBody"];
    }
}

- (void) registerAlarm:(OBAAlarmState*)alarmState {
    
    if( alarmState.alarmId )
        return;
    
    OBAArrivalAndDepartureInstanceRef * ref = alarmState.instanceRef;
    BOOL onArrival = alarmState.onArrival;
    NSInteger alarmTimeOffset = alarmState.alarmTimeOffset;
    NSDictionary * notificationOptions = alarmState.notificationOptions;
    
    [self.modelService registerAlarmForArrivalAndDepartureAtStop:ref onArrival:onArrival alarmTimeOffset:alarmTimeOffset notificationOptions:notificationOptions withDelegate:self withContext:alarmState];
}

- (void) updateAlarmsWithMatchPreviousItinerary:(BOOL)matchPreviousItinerary {

    NSMutableArray * alarmsToKeep = [[NSMutableArray alloc] init];
    NSMutableArray * alarmsToCancel = [[NSMutableArray alloc] init];

    if (matchPreviousItinerary) {
        for( OBAAlarmState * alarmState in _currentAlarms ) {
            NSInteger index = [self matchBestIndexForTripState:alarmState.tripState];
            if( 0 <= index && index < [_currentStates count] ) {
                OBATripState * updatedState = [_currentStates objectAtIndex:index];
                alarmState.tripState = updatedState;
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
