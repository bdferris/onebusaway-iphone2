#import "OBALocationManager.h"
#import "OBAModelService.h"
#import "OBATripQuery.h"
#import "OBAItinerariesV2.h"
#import "OBATripState.h"


@protocol OBATripControllerDelegate <NSObject>
@optional
-(void) refreshTripState:(OBATripState*)tripState;
-(void) chooseFromItineraries:(NSArray*)itineraries;
-(void) refreshingItineraries;
-(void) refreshingItinerariesCompleted;
-(void) refreshingItinerariesFailed:(NSError*)error;
@end


@interface OBATripController : NSObject <OBAModelServiceDelegate> {
    OBATripQuery * _query;
    NSArray * _itineraries;
    NSDate * _lastUpdate;
    OBAItineraryV2 * _currentItinerary;
    NSMutableArray * _currentStates;
    NSInteger _currentStateIndex;
    NSTimer * _refreshTimer;
    NSMutableArray * _currentAlarms;
}

@property (nonatomic,retain) OBALocationManager * locationManager;
@property (nonatomic,retain) OBAModelService * modelService;
@property (nonatomic,retain) OBAModelDAO * modelDao;
@property (nonatomic,retain) id<OBATripControllerDelegate> delegate;

- (void) planTripWithQuery:(OBATripQuery*)query;
- (void) selectItinerary:(OBAItineraryV2*)itinerary;
- (void) showItineraries;
- (void) refresh;

@property (nonatomic,readonly) OBATripQuery * query;
@property (nonatomic,readonly) NSDate * lastUpdate;
@property (nonatomic,readonly) NSArray * itineraries;
@property (nonatomic,readonly) OBAItineraryV2 * currentItinerary;
@property (nonatomic,readonly) OBATripState * tripState;

@property (nonatomic,readonly) BOOL hasPreviousState;
@property (nonatomic,readonly) BOOL hasCurrentState;
@property (nonatomic,readonly) BOOL hasNextState;

- (void) moveToPrevState;
- (void) moveToNextState;
- (void) moveToCurrentState;

- (void) updateAlarm:(BOOL)enabled forTripState:(OBATripState*)tripState alarmTimeOffset:(NSInteger)alertTimeOffest;
- (BOOL) isAlarmEnabledForTripState:(OBATripState*)tripState;

@end
