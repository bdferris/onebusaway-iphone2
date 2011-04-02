#import "OBAModelService.h"
#import "OBAPlace.h"
#import "OBAItinerariesV2.h"
#import "OBATripState.h"


@protocol OBATripControllerDelegate <NSObject>
-(void) refreshTripState:(OBATripState*)tripState;
@end


@interface OBATripController : NSObject <OBAModelServiceDelegate> {
    OBAPlace * _placeFrom;
    OBAPlace * _placeTo;
    OBAItineraryV2 * _currentItinerary;
    NSMutableArray * _currentStates;
    NSInteger _currentStateIndex;
}

@property (nonatomic,retain) OBAModelService * modelService;
@property (nonatomic,retain) id<OBATripControllerDelegate> delegate;

- (void) planTripFrom:(OBAPlace*)fromPlace to:(OBAPlace*)toPlace;

@property (nonatomic,readonly) OBAPlace * placeFrom;
@property (nonatomic,readonly) OBAPlace * placeTo;

@property (nonatomic,readonly) OBATripState * tripState;

@property (nonatomic,readonly) BOOL hasPreviousState;
@property (nonatomic,readonly) BOOL hasNextState;

- (void) moveToPrevState;
- (void) moveToNextState;
- (void) moveToCurrentState;


@end
