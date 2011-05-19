#import "OBAPlace.h"


@implementation OBAPlace

@synthesize name;
@synthesize location;
@synthesize type;
@synthesize stopIds;

- (id) initWithCoder:(NSCoder*)coder {
    self = [super init];
	if( self ) {
		self.name =  [coder decodeObjectForKey:@"name"];
        self.location = [coder decodeObjectForKey:@"location"];
        self.type = [coder decodeIntForKey:@"type"];
        self.stopIds = [coder decodeObjectForKey:@"stopIds"];
	}
	return self;
}

+ (OBAPlace*) placeWithPlace:(OBAPlace*)other {
    OBAPlace * place = [[[OBAPlace alloc] init] autorelease];
    place.name = other.name;
    place.location = other.location;
    place.type = other.type;
    return place;
}

+ (OBAPlace*) placeWithName:(NSString*)name {
    return [self placeWithName:name location:nil];
}

+ (OBAPlace*) placeWithName:(NSString*)name location:(CLLocation*)location {
    OBAPlace * place = [[[OBAPlace alloc] init] autorelease];
    place.name = name;
    place.location = location;
    place.type = OBAPlaceTypePlain;
    return place;
}

+ (OBAPlace*) placeWithBookmarkName:(NSString*)name location:(CLLocation*)location {
    OBAPlace * place = [[[OBAPlace alloc] init] autorelease];
    place.name = name;
    place.location = location;
    place.type = OBAPlaceTypeBookmark;
    return place;
}

+ (OBAPlace*) placeWithName:(NSString*)name coordinate:(CLLocationCoordinate2D)coordinate {
    CLLocation * location = [[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude] autorelease];
    return [self placeWithBookmarkName:name location:location];
}

+ (OBAPlace*) placeWithCurrentLocation {
    OBAPlace * place = [[[OBAPlace alloc] init] autorelease];
    place.name = @"Current Location";
    place.location = nil;
    place.type = OBAPlaceTypeCurrentLocation;
    return place;
}

+ (OBAPlace*) placeWithDroppedPinLocation:(CLLocation*)location {
    OBAPlace * place = [[[OBAPlace alloc] init] autorelease];
    place.name = @"Dropped Pin";
    place.location = location;
    place.type = OBAPlaceTypeDroppedPin;
    return place; 
}

- (void) dealloc {
    self.name = nil;
    self.location = nil;
    self.stopIds = nil;
    [super dealloc];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"OBAPlace: name=%@ type=%d", self.name, self.type];
}

- (BOOL) isPlain {
    return self.type == OBAPlaceTypePlain;
}

- (BOOL) isCurrentLocation {
    return self.type == OBAPlaceTypeCurrentLocation;
}

- (BOOL) isBookmark {
    return self.type == OBAPlaceTypeBookmark;
}

- (BOOL) isDroppedPin {
    return self.type == OBAPlaceTypeDroppedPin;
}

- (BOOL) isRecent {
    return self.type == OBAPlaceTypeRecent;
}

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
	[coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeInt:self.type forKey:@"type"];
    [coder encodeObject:self.stopIds forKey:@"stopIds"];
}

@end
