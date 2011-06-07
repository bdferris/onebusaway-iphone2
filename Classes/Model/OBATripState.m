#import "OBATripState.h"
#import "OBAPresentation.h"


@implementation OBATripState

@synthesize placeFrom;
@synthesize placeTo;
@synthesize itinerary;

@synthesize type;
@synthesize itineraries;
@synthesize selectedItineraryIndex;
@synthesize showStartTime;
@synthesize isLateStartTime;
@synthesize walkToStop;
@synthesize walkToPlace;
@synthesize stop;
@synthesize departures;
@synthesize departureItineraries;
@synthesize selectedDepartureIndex;
@synthesize continuesAs;
@synthesize ride;
@synthesize arrivals;
@synthesize arrivalItineraries;
@synthesize selectedArrivalIndex;

@synthesize region;

- (id) init {
    self = [super init];
    if (self) {
        self.selectedItineraryIndex = NSNotFound;
        self.selectedDepartureIndex = NSNotFound;
        self.selectedArrivalIndex = NSNotFound;
    }
    return self;
}

- (void) dealloc {
    self.placeFrom = nil;
    self.placeTo = nil;
    self.itinerary = nil;
    self.itineraries = nil;
    self.walkToStop = nil;
    self.walkToPlace = nil;
    self.stop = nil;
    self.departures = nil;
    self.departureItineraries = nil;
    self.continuesAs = nil;
    self.ride = nil;
    self.arrivals = nil;
    self.arrivalItineraries = nil;
    [super dealloc];
}

- (BOOL) noResultsFound {
    return self.type == OBATripStateTypeItineraries && [self.itineraries count] == 0;
}

- (OBATransitLegV2*) departure {
    if (self.selectedDepartureIndex == NSNotFound)
        return nil;
    return [self.departures objectAtIndex:self.selectedDepartureIndex];
}

- (OBATransitLegV2*) arrival {
    if (self.selectedArrivalIndex == NSNotFound)
        return nil;
    return [self.arrivals objectAtIndex:self.selectedArrivalIndex];
}

- (NSString*) description {
    NSMutableString * d = [NSMutableString string];
    [d appendString:@"OBATripState("];
    if (self.itineraries)
        [d appendFormat:@"itineraries=%d",[self.itineraries count]];
    if (self.walkToStop)
        [d appendFormat:@"walkToStop=%@",self.walkToStop.stopId];
    if (self.walkToPlace)
        [d appendFormat:@"walkToPlace=%@",[self.walkToPlace description]];
    if (self.stop)
        [d appendFormat:@"stop=%@",stop.stopId];
    if (self.departures)
        [d appendFormat:@"departures=%d",[self.departures count]];
    if (self.ride)
        [d appendFormat:@"ride=%@ - %@",[OBAPresentation getRouteShortNameForTransitLeg:self.ride], [OBAPresentation getTripHeadsignForTransitLeg:self.ride]];
    if (self.arrivals)
        [d appendFormat:@"arrivals=%d",[self.arrivals count]];
    [d appendString:@")"];
    return d;
}

@end
