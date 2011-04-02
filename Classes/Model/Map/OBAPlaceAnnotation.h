#import "OBAPlace.h"


@interface OBAPlaceAnnotation : NSObject <MKAnnotation> {
    OBAPlace * _place;
}

- (id) initWithPlace:(OBAPlace*)place;

@property (nonatomic,readonly) OBAPlace  * place;

@end
