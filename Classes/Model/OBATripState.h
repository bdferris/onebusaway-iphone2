#import "OBAItineraryV2.h"
#import "OBAPlace.h"

typedef enum {    
    OBATripStateTypeItineraries,
    OBATripStateTypeWalk,
    OBATripStateTypeDepartures,
    OBATripStateTypeContinueAs,
    OBATripStateTypeRide,
    OBATripStateTypeArrivals,
} OBATripStateType;

@interface OBATripState : NSObject {
    
}

@property (nonatomic,retain) OBAPlace * placeFrom;
@property (nonatomic,retain) OBAPlace * placeTo;
@property (nonatomic,retain) OBAItineraryV2 * itinerary;

@property (nonatomic) OBATripStateType type;

@property (nonatomic,retain) NSArray * itineraries;
@property (nonatomic) NSUInteger selectedItineraryIndex;
@property (nonatomic,readonly) BOOL noResultsFound;

@property (nonatomic) BOOL showStartTime;

@property (nonatomic) BOOL isLateStartTime;
@property (nonatomic,retain) OBAStopV2 * walkToStop;
@property (nonatomic,retain) OBAPlace * walkToPlace;

@property (nonatomic,retain) NSArray * departures;
@property (nonatomic,retain) NSArray * departureItineraries;
@property (nonatomic) NSUInteger selectedDepartureIndex;
@property (nonatomic,readonly) OBATransitLegV2 * departure;

@property (nonatomic,retain) OBATransitLegV2 * continuesAs;
@property (nonatomic,retain) OBATransitLegV2 * ride;

@property (nonatomic,retain) NSArray * arrivals;
@property (nonatomic,retain) NSArray * arrivalItineraries;
@property (nonatomic) NSUInteger selectedArrivalIndex;
@property (nonatomic,readonly) OBATransitLegV2 * arrival;

@property (nonatomic) MKCoordinateRegion region;

@end
