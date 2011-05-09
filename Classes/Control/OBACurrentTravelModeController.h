#import "OBALocationManager.h"
#import "OBAModelService.h"
#import "OBACurrentTravelModeState.h"


@class OBACurrentTravelModeController;

@protocol OBACurrentTravelModeDelegate <NSObject>
- (void) didUpdateCurrentTravelModes:(NSArray*)modes controller:(OBACurrentTravelModeController*)controller;
@end


@interface OBACurrentTravelModeController : NSObject <OBALocationManagerDelegate,OBAModelServiceDelegate> {
    id<OBACurrentTravelModeDelegate> _delegate;
    NSMutableArray * _delegates;
    NSTimer * _timer;
    NSMutableArray * _locations;
    NSArray * _currentModes;
    OBACurrentTravelModeState * _streetState;
}

@property (nonatomic,retain) OBALocationManager * locationManager;
@property (nonatomic,retain) OBAModelService * modelService;
@property (nonatomic,retain) id<OBACurrentTravelModeDelegate> delegate;

- (NSArray*) currentModes;

@end
