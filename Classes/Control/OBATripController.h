#import "OBAModelService.h"
#import "OBAPlace.h"
#import "OBAItinerariesV2.h"
#import "OBATripState.h"


@protocol OBATripControllerDelegate <NSObject>
-(void) refreshTrip;
@end


@interface OBATripController : NSObject <OBAModelServiceDelegate> {
    OBAItineraryV2 * _currentItinerary;
}

@property (nonatomic,retain) OBAModelService * modelService;
@property (nonatomic,retain) id<OBATripControllerDelegate> delegate;

- (void) planTripFrom:(OBAPlace*)fromPlace to:(OBAPlace*)toPlace;

@property (nonatomic,readonly) OBATripState * tripState;

@property (nonatomic,readonly) BOOL hasPreviousState;
@property (nonatomic,readonly) BOOL hasNextState;

- (void) moveToPrevState;
- (void) moveToNextState;
- (void) moveToCurrentState;


@end
