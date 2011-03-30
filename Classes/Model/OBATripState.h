#import "OBAItineraryV2.h"


typedef enum {
    OBATripStateTypeCompleteItinerary
} OBATripStateType;


@interface OBATripState : NSObject {
    
}

@property (nonatomic) OBATripStateType type;
@property (nonatomic,retain) OBAItineraryV2 * itinerary;
@property (nonatomic) MKCoordinateRegion preferredRegion;
@property (nonatomic,retain) NSArray * overlays;


@end
