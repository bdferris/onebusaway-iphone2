#import "OBAAlarmRef.h"


@interface OBAAlarmState : NSObject {
    OBAAlarmRef * _alarmRef;
}

- (id) initWithAlarmRef:(OBAAlarmRef*)alarmRef;

@property (nonatomic,readonly) OBAAlarmRef * alarmRef;
@property (nonatomic,retain) NSString * alarmId;
@property (nonatomic) NSInteger alarmTimeOffset;
@property (nonatomic) NSInteger userAlarmTimeOffset;
@property (nonatomic,retain) NSDictionary * notificationOptions;

@end
