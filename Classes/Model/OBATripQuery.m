#import "OBATripQuery.h"


@implementation OBATripQuery

@synthesize placeFrom = _placeFrom;
@synthesize placeTo = _placeTo;
@synthesize time = _time;
@synthesize optimizeFor = _optimizeFor;

@synthesize automaticallyPickBestItinerary;

- (id) initWithPlaceFrom:(OBAPlace*)placeFrom placeTo:(OBAPlace*)placeTo time:(OBATargetTime*)targetTime optimizeFor:(OBATripQueryOptimizeForType)optimizeFor {

    self = [super init];
    if (self) {
        _placeFrom = [placeFrom retain];
        _placeTo = [placeTo retain];
        _time = [targetTime retain];
        _optimizeFor = optimizeFor;
    }
    return self;
}

- (void) dealloc {
    [_placeFrom release];
    [_placeTo release];
    [_time release];
    [super dealloc];
}
@end
