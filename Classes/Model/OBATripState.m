#import "OBATripState.h"


@implementation OBATripState

@synthesize placeFrom;
@synthesize placeTo;
@synthesize itinerary;

@synthesize showTripSummary;
@synthesize startTime;
@synthesize walkToStop;
@synthesize walkToPlace;
@synthesize departure;
@synthesize continuesAs;
@synthesize ride;
@synthesize arrival;

@synthesize region;

- (void) dealloc {
    self.placeFrom = nil;
    self.placeTo = nil;
    self.itinerary = nil;
    self.startTime = nil;
    self.walkToStop = nil;
    self.walkToPlace = nil;
    self.departure = nil;
    self.continuesAs = nil;
    self.ride = nil;
    self.arrival = nil;
    [super dealloc];
}

@end
