@interface OBAPlace : NSObject {

}

- (id) initWithName:(NSString*)name coordinate:(CLLocationCoordinate2D)coordinate;
- (id) initWithCoder:(NSCoder*)coder;

+ (OBAPlace*) placeWithPlace:(OBAPlace*)other;
+ (OBAPlace*) placeWithName:(NSString*)name;
+ (OBAPlace*) placeWithCurrentLocation;

@property (nonatomic,retain) NSString * name;
@property (nonatomic,retain) CLLocation * location;
@property (nonatomic) BOOL useCurrentLocation;
@property (nonatomic) BOOL isBookmark;
@property (nonatomic,retain) NSArray * stopIds;

@end
