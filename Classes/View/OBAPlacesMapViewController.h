@interface OBAPlacesMapViewController : UIViewController <MKMapViewDelegate> {
    NSArray * _places;
}

- (id) initWithPlaces:(NSArray*)places;

@property (nonatomic,retain) id target;
@property (nonatomic) SEL action;
@property (nonatomic) SEL cancelAction;

@end
