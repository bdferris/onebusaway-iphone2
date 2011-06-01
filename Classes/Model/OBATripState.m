#import "OBATripState.h"


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

@end
