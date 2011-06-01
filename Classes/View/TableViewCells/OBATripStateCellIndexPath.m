#import "OBATripStateCellIndexPath.h"


@implementation OBATripStateCellIndexPath

@synthesize type = _type;
@synthesize row = _row;

- (id) initWithType:(OBATripStateCellType)type row:(NSUInteger)row {
    self = [super init];
    if (self) {
        _type = type;
        _row = row;
    }
    return self;
}

+ (OBATripStateCellIndexPath*) indexPathWithType:(OBATripStateCellType)type row:(NSUInteger)row {
    return [[[OBATripStateCellIndexPath alloc] initWithType:type row:row] autorelease];
}

+ (OBATripStateCellIndexPath*) indexPathWithType:(OBATripStateCellType)type {
    return [self indexPathWithType:type row:0];
}

@end
