typedef enum {
    OBAPlaceTypePlain=0,
    OBAPlaceTypeCurrentLocation=1,
    OBAPlaceTypeBookmark=2,
    OBAPlaceTypeDroppedPin=3,
    OBAPlaceTypeRecent=4
} OBAPlaceType;

@interface OBAPlace : NSObject {

}

- (id) initWithCoder:(NSCoder*)coder;

+ (OBAPlace*) placeWithPlace:(OBAPlace*)other;
+ (OBAPlace*) placeWithName:(NSString*)name;
+ (OBAPlace*) placeWithName:(NSString*)name location:(CLLocation*)location;
+ (OBAPlace*) placeWithName:(NSString*)name coordinate:(CLLocationCoordinate2D)coordinate;
+ (OBAPlace*) placeWithBookmarkName:(NSString*)name location:(CLLocation*)location;
+ (OBAPlace*) placeWithCurrentLocation;
+ (OBAPlace*) placeWithDroppedPinLocation:(CLLocation*)location;

@property (nonatomic,retain) NSString * name;
@property (nonatomic,retain) CLLocation * location;
@property (nonatomic) OBAPlaceType type;

@property (nonatomic,readonly) BOOL isPlain;
@property (nonatomic,readonly) BOOL isCurrentLocation;
@property (nonatomic,readonly) BOOL isBookmark;
@property (nonatomic,readonly) BOOL isDroppedPin;
@property (nonatomic,readonly) BOOL isRecent;

@property (nonatomic,retain) NSArray * stopIds;

@end
