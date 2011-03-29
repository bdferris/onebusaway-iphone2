#import "OBAPlace.h"


@implementation OBAPlace

@synthesize name;
@synthesize location;

- (void) dealloc {
    self.name = nil;
    self.location = nil;
    [super dealloc];
}

@end
