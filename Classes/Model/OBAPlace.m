#import "OBAPlace.h"


@implementation OBAPlace

@synthesize name;
@synthesize location;
@synthesize useCurrentLocation;
@synthesize isBookmark;
@synthesize stopIds;


- (id) initWithName:(NSString*)placeName coordinate:(CLLocationCoordinate2D)coordinate {
    self = [super init];
    if( self ) {
        self.name = name;
        self.location = [[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude] autorelease];
    }
    return self;
}

- (id) initWithCoder:(NSCoder*)coder {
    self = [super init];
	if( self ) {
		self.name =  [coder decodeObjectForKey:@"name"];
        self.location = [coder decodeObjectForKey:@"location"];
        self.useCurrentLocation = [coder decodeBoolForKey:@"useCurrentLocation"];
        self.isBookmark = [coder decodeBoolForKey:@"isBookmark"];
        self.stopIds = [coder decodeObjectForKey:@"stopIds"];
	}
	return self;
}

+ (OBAPlace*) placeWithPlace:(OBAPlace*)other {
    OBAPlace * place = [[[OBAPlace alloc] init] autorelease];
    place.name = other.name;
    place.location = other.location;
    place.useCurrentLocation = other.useCurrentLocation;
    place.isBookmark = other.isBookmark;
    return place;
}

+ (OBAPlace*) placeWithName:(NSString*)name {
    OBAPlace * place = [[[OBAPlace alloc] init] autorelease];
    place.name = name;
    place.location = nil;
    place.useCurrentLocation = FALSE;
    return place;
}

+ (OBAPlace*) placeWithCurrentLocation {
    OBAPlace * place = [[[OBAPlace alloc] init] autorelease];
    place.name = @"Current Location";
    place.location = nil;
    place.useCurrentLocation = TRUE;
    return place;
}

- (void) dealloc {
    self.name = nil;
    self.location = nil;
    self.stopIds = nil;
    [super dealloc];
}

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
	[coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeBool:self.useCurrentLocation forKey:@"useCurrentLocation"];
    [coder encodeBool:self.isBookmark forKey:@"isBookmark"];
    [coder encodeObject:self.stopIds forKey:@"stopIds"];
}

@end
