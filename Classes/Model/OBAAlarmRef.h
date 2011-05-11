#import "OBAArrivalAndDepartureInstanceRef.h"

typedef enum {
    OBAAlarmTypeStart,
    OBAAlarmTypeDeparture,
    OBAAlarmTypeArrival
} OBAAlarmType;


@interface OBAAlarmRef : NSObject {
    
}

- (id) initWithType:(OBAAlarmType)type instanceRef:(OBAArrivalAndDepartureInstanceRef*)ref;

@property (nonatomic) OBAAlarmType alarmType;
@property (nonatomic,retain) OBAArrivalAndDepartureInstanceRef * instanceRef;

- (BOOL) isEqualToAlarmRef:(OBAAlarmRef*)ref;

@end
