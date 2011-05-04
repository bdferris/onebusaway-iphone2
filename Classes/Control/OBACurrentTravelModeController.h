#import "OBALocationManager.h"
#import "OBAModelService.h"
#import "OBACurrentTravelModeState.h"


@class OBACurrentTravelModeController;

@protocol OBACurrentTravelModeDelegate <NSObject>
- (void) didUpdateCurrentTravelModes:(NSArray*)modes controller:(OBACurrentTravelModeController*)controller;
@end


@interface OBACurrentTravelModeController : NSObject <OBALocationManagerDelegate,OBAModelServiceDelegate> {
    NSMutableArray * _delegates;
    NSTimer * _timer;
    NSMutableArray * _locations;
    NSArray * _currentModes;
}

@property (nonatomic,retain) OBALocationManager * locationManager;
@property (nonatomic,retain) OBAModelService * modelService;

- (void) start;
- (void) stop;

- (void) addDelegate:(id<OBACurrentTravelModeDelegate>)delegate;
- (void) removeDelegate:(id<OBACurrentTravelModeDelegate>)delegate;

- (NSArray*) currentModes;

@end
