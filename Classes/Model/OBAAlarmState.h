#import "OBATripState.h"
#import "OBAArrivalAndDepartureInstanceRef.h"


@interface OBAAlarmState : NSObject {
    
}

@property (nonatomic,retain) OBATripState * tripState;        
@property (nonatomic,retain) NSString * alarmId;
@property (nonatomic,retain) OBAArrivalAndDepartureInstanceRef * instanceRef;
@property (nonatomic) BOOL onArrival;
@property (nonatomic) NSInteger alarmTimeOffset;
@property (nonatomic,retain) NSDictionary * notificationOptions;

@end
