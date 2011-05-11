#import "OBAAlarmRef.h"


@implementation OBAAlarmRef

@synthesize alarmType;
@synthesize instanceRef;

- (id) initWithType:(OBAAlarmType)type instanceRef:(OBAArrivalAndDepartureInstanceRef*)ref {
    self = [super init];
    if (self) {
        self.alarmType = type;
        self.instanceRef = ref;
    }
    return self;
}

- (void) dealloc {
    self.instanceRef = nil;
    [super dealloc];
}

- (BOOL) isEqual:(id)object {
    if (self == object)
        return TRUE;
    if (object == nil)
        return FALSE;
    if ( ![object isKindOfClass:[OBAAlarmRef class]] )
        return FALSE;
    OBAAlarmRef * ref = object;
    return [self isEqualToAlarmRef:ref];
}

- (BOOL) isEqualToAlarmRef:(OBAAlarmRef*)ref {
    if ( self.alarmType != ref.alarmType )
        return FALSE;
    if ( ![self.instanceRef isEqual:ref.instanceRef] )
        return FALSE;
    return TRUE;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"(type=%d instance=%@)", self.alarmType, [self.instanceRef description]];
}

@end
