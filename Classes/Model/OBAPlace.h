@interface OBAPlace : NSObject {

}

- (id) initWithName:(NSString*)name coordinate:(CLLocationCoordinate2D)coordinate;

@property (nonatomic,retain) NSString * name;
@property (nonatomic,retain) CLLocation * location;
@end
