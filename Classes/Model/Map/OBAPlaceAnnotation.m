#import "OBAPlaceAnnotation.h"


@implementation OBAPlaceAnnotation

@synthesize place = _place;
@synthesize animatesDrop;

- (id) initWithPlace:(OBAPlace*)place {
    self = [super init];
    if (self) {
        _place = [place retain];
    }
    return self;
}

- (void) dealloc {
    [_place release];
    [super dealloc];
}

- (CLLocationCoordinate2D) coordinate {
    return _place.location.coordinate;
}

- (NSString*) title {
    return _place.name;
}

- (NSString*) subtitle {
    return nil;
}

@end
