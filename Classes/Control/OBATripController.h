#import "OBAModelService.h"
#import "OBAPlace.h"
#import "OBAItinerariesV2.h"


@protocol OBATripControllerDelegate <NSObject>
-(void) refreshTrip;
@end


@interface OBATripController : NSObject <OBAModelServiceDelegate> {
    OBAItineraryV2 * _currentItinerary;
}

@property (nonatomic,retain) OBAModelService * modelService;
@property (nonatomic,retain) id<OBATripControllerDelegate> delegate;

- (void) planTripFrom:(OBAPlace*)fromPlace to:(OBAPlace*)toPlace;

@property (nonatomic,readonly) NSArray * overlays;

@end
