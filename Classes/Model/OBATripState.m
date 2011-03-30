#import "OBATripState.h"


@implementation OBATripState

@synthesize type;
@synthesize itinerary;
@synthesize preferredRegion;
@synthesize overlays;

- (void) dealloc {
    self.itinerary = nil;
    self.overlays = nil;
    [super dealloc];
}

@end
