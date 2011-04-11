#import "OBATargetTime.h"


@implementation OBATargetTime

@synthesize type;
@synthesize time;

- (id) initWithType:(OBATargetTimeType)targetType time:(NSDate*)targetTime {
    self = [super init];
    if( self ) {
        self.type = targetType;
        self.time = targetTime;
    }
    return self;
}

+ (OBATargetTime*) timeNow {
    return [[[OBATargetTime alloc] initWithType:OBATargetTimeTypeNow time:nil] autorelease];
}

+ (OBATargetTime*) timeDepartBy:(NSDate*)targetTime {
    return [[[OBATargetTime alloc] initWithType:OBATargetTimeTypeDepartBy time:targetTime] autorelease];
}

+ (OBATargetTime*) timeArriveBy:(NSDate*)targetTime {
    return [[[OBATargetTime alloc] initWithType:OBATargetTimeTypeArriveBy time:targetTime] autorelease];
}

- (void) dealloc {
    self.time = time;
    [super dealloc];
}
@end
