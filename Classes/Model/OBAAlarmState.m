#import "OBAAlarmState.h"


@implementation OBAAlarmState

@synthesize alarmRef = _alarmRef;
@synthesize alarmId;
@synthesize alarmTimeOffset;
@synthesize userAlarmTimeOffset;
@synthesize notificationOptions;

- (id) initWithAlarmRef:(OBAAlarmRef*)alarmRef {
    self = [super init];
    if (self) {
        _alarmRef = [alarmRef retain];
    }
    return self;
}

- (void) dealloc {
    [_alarmRef release];
    self.alarmId = nil;
    self.notificationOptions = nil;
    [super dealloc];
}

@end
