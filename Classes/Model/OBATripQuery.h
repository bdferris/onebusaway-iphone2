#import "OBATargetTime.h"
#import "OBAPlace.h"


typedef enum {
    OBATripQueryOptimizeForTypeDefault = 0,
    OBATripQueryOptimizeForTypeMinimizeTime = 1,
    OBATripQueryOptimizeForTypeMinimizeTransfers = 2,
    OBATripQueryOptimizeForTypeMinimizeWalking = 3
} OBATripQueryOptimizeForType;


@interface OBATripQuery : NSObject {
    OBAPlace * _placeFrom;
    OBAPlace * _placeTo;
    OBATargetTime * _time;
    OBATripQueryOptimizeForType _optimizeFor;
}

- (id) initWithPlaceFrom:(OBAPlace*)placeFrom placeTo:(OBAPlace*)placeTo time:(OBATargetTime*)targetTime optimizeFor:(OBATripQueryOptimizeForType)optimizeFor;

@property (nonatomic,readonly) OBAPlace * placeFrom;
@property (nonatomic,readonly) OBAPlace * placeTo;
@property (nonatomic,readonly) OBATargetTime * time;
@property (nonatomic,readonly) OBATripQueryOptimizeForType optimizeFor;

@property (nonatomic) BOOL automaticallyPickBestItinerary;

@end
