//
//  OBACurrentTravelModeController.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBACurrentTravelModeController.h"
#import "OBACurrentVehicleEstimateV2.h"
#import "OBACurrentTravelModeState.h"
#import "OBAPresentation.h"


static const NSUInteger kMaxLocationReadingCount = 8;
static const NSUInteger kPreferredLocationReadingUpdateInterval = 30;
static const NSUInteger kMinLocationReadingAccuracy = 100;
static const NSUInteger kMaxLocationReadingAge = 240;


@interface OBACurrentTravelModeController (Private)

- (void) refresh;
- (void) clearTimer;

@end



@implementation OBACurrentTravelModeController

@synthesize locationManager;
@synthesize modelService;

- (id) init {
    self = [super init];
    if( self ) {
        _delegates = [[NSMutableArray alloc] init];
        _locations = [[NSMutableArray alloc] init];
        _currentModes = [[NSArray alloc] init];
        
        //OBACurrentTravelModeState * streetState = [[OBACurrentTravelModeState alloc] init];
        //streetState.label = @"On foot";
        //[currentModes addObject:streetState];
        //[streetState release];

    }
    return self;
}

- (void) dealloc {
    [self clearTimer];
    [_delegates release];
    [_locations release];
    [_currentModes release];
    self.locationManager = nil;
    self.modelService = nil;
    [super dealloc];
}

- (void) start {
    //_timer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh) userInfo:nil repeats:TRUE] retain];
}

- (void) stop {
    
}

- (void) addDelegate:(id<OBACurrentTravelModeDelegate>)delegate {
    [_delegates addObject:delegate];
}

- (void) removeDelegate:(id<OBACurrentTravelModeDelegate>)delegate {
    [_delegates removeObject:delegate];
}

- (NSArray*) currentModes {
    return _currentModes;
}

#pragma mark OBALocationManagerDelegate Methods

- (void) locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location {
    
    /**
     * Only add a reading if it's accurate enough
     */
    if( location.horizontalAccuracy < kMinLocationReadingAccuracy ) {
        if( [_locations count] >= kMaxLocationReadingCount ) {
            CLLocation * prevLocation = [_locations objectAtIndex:([_locations count] - 1)];
            NSTimeInterval interval = [location.timestamp timeIntervalSinceDate:prevLocation.timestamp];
            if( interval > kPreferredLocationReadingUpdateInterval )
                [_locations addObject:location];
        }
        else {
            [_locations addObject:location];
        }
    }
    
    /**
     * We can't have more than kMaxLocationReadingCount readings in the buffer
     */
    while( [_locations count] > kMaxLocationReadingCount ) {
        [_locations removeObjectAtIndex:0];
    }
    
    /**
     * Prune any readings older than max-age
     */
    while ([_locations count] > 0) {
        CLLocation * location = [_locations objectAtIndex:0];
        NSTimeInterval interval = -[location.timestamp timeIntervalSinceNow];
        if( interval > kMaxLocationReadingAge )
            [_locations removeObjectAtIndex:0];
        else
            break;
        
    }
}

- (void) locationManager:(OBALocationManager *)manager didFailWithError:(NSError*)error {
    
}


- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {    

    OBAListWithRangeAndReferencesV2 * entry = obj;
    NSMutableArray * currentModes = [[NSMutableArray alloc] init];
    
    
    NSArray * values = [entry.values sortedArrayUsingComparator:^(id a, id b) {
        OBACurrentVehicleEstimateV2 * v1 = a;
        OBACurrentVehicleEstimateV2 * v2 = b;
        if( v1.probability == v2.probability )
            return NSOrderedSame;
        return v1.probability < v2.probability ? NSOrderedDescending : NSOrderedAscending;
    }];
    
    for( OBACurrentVehicleEstimateV2 * estimate in values ) {
        
        OBACurrentTravelModeState * state = [[OBACurrentTravelModeState alloc] init];
        
        NSMutableString * label = [[NSMutableString alloc] init];
        
        [label appendFormat:@"p=%0.1f",estimate.probability];
        
        OBATripStatusV2 * status = estimate.tripStatus;

        if( status ) {
            
            if( status.vehicleId )
                [label appendFormat:@" vid=%@",status.vehicleId];

            OBATripV2 * trip = status.activeTrip;
            state.blockId = trip.blockId;
            state.serviceDate = status.serviceDate;
            state.vehicleId = status.vehicleId;
            
            NSString * shortName = [OBAPresentation getRouteShortNameForTrip:trip];
            NSString * tripHeadsign = [OBAPresentation getTripHeadsignForTrip:trip];
            [label appendFormat:@" %@ - %@",shortName,tripHeadsign];
        }

        state.label = label;
        
        NSLog(@"current vehicle estimate: %@", label);
        NSLog(@"  debug: %@", estimate.debug);
        
        [currentModes addObject:state];
        [state release];
        [label release];
    }
    
    [_currentModes release];
    _currentModes = currentModes;
    
    for( id<OBACurrentTravelModeDelegate> delegate in _delegates ) {
        [delegate didUpdateCurrentTravelModes:_currentModes controller:self];
    }
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
    
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
    
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    
}

@end



@implementation OBACurrentTravelModeController (Private)

- (void) refresh {
    OBALogDebug(@"Locations: %d", [_locations count]);
    if( [_locations count] > 0 ) {
        OBAModelService * service = self.modelService;
        [service requestCurrentVehicleEstimatesForLocations:_locations withDelegate:self withContext:nil];
    }
}
     
- (void) clearTimer {
    [_timer invalidate];
    [_timer release];
    _timer = nil;
}

@end
