#import "OBAPlace.h"


@implementation OBAPlace

@synthesize name;
@synthesize location;

- (id) initWithName:(NSString*)placeName coordinate:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if( self ) {
        self.name = name;
        self.location = [[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude] autorelease];
    }
    return self;
}

- (void) dealloc {
    self.name = nil;
    self.location = nil;
    [super dealloc];
}

@end
