#import "OBAItineraryV2.h"
#import "OBAPlace.h"


@interface OBATripState : NSObject {
    
}

@property (nonatomic,retain) OBAPlace * placeFrom;
@property (nonatomic,retain) OBAPlace * placeTo;
@property (nonatomic,retain) OBAItineraryV2 * itinerary;

@property (nonatomic) BOOL showTripSummary;
@property (nonatomic,retain) NSDate * startTime;
@property (nonatomic) BOOL isLateStartTime;
@property (nonatomic,retain) OBAStopV2 * walkToStop;
@property (nonatomic,retain) OBAPlace * walkToPlace;
@property (nonatomic,retain) OBATransitLegV2 * departure;
@property (nonatomic,retain) OBATransitLegV2 * continuesAs;
@property (nonatomic,retain) OBATransitLegV2 * ride;
@property (nonatomic,retain) OBATransitLegV2 * arrival;

@property (nonatomic) MKCoordinateRegion region;

@end
