#import "OBALocationManager.h"
#import "OBAModelService.h"
#import "OBATripQuery.h"
#import "OBAItinerariesV2.h"
#import "OBATripState.h"
#import "OBAAlarmState.h"


@protocol OBATripControllerDelegate <NSObject>
@optional
-(void) refreshingItineraries;
-(void) refreshingItinerariesCompleted;
-(void) refreshingItinerariesFailed:(NSError*)error;
-(void) refreshTripState:(OBATripState*)tripState;
@end

@interface OBATripController : NSObject <OBAModelServiceDelegate> {
    id<OBATripControllerDelegate> _delegate;
    NSInteger _queryIndex;
    OBATripQuery * _query;
    id<OBAModelServiceRequest> _queryRequest;
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
- (void) refresh;

@property (nonatomic,readonly) NSInteger queryIndex;
@property (nonatomic,readonly) OBATripQuery * query;
@property (nonatomic,readonly) BOOL isRefreshingItineraries;
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

- (BOOL) isAlarmEnabledForType:(OBAAlarmType)alarmType tripState:(OBATripState*)tripState;
- (void) updateAlarm:(BOOL)enabled withType:(OBAAlarmType)alarmType tripState:(OBATripState*)tripState alarmTimeOffset:(NSInteger)alarmTimeOffset;
- (NSInteger) getAlarmTimeOffsetForType:(OBAAlarmType)alarmType tripState:(OBATripState*)tripState;
- (void) handleAlarm:(NSString*)alarmId;

@end
