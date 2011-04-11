#import "OBATargetTime.h"
#import "OBAPlace.h"

@interface OBATripQuery : NSObject {
    OBAPlace * _placeFrom;
    OBAPlace * _placeTo;
    OBATargetTime * _time;
}

- (id) initWithPlaceFrom:(OBAPlace*)placeFrom placeTo:(OBAPlace*)placeTo time:(OBATargetTime*)targetTime;

@property (nonatomic,readonly) OBAPlace * placeFrom;
@property (nonatomic,readonly) OBAPlace * placeTo;
@property (nonatomic,readonly) OBATargetTime * time;

@property (nonatomic) BOOL automaticallyPickBestItinerary;

@end
