typedef enum {
    OBATripStateCellTypeNoResultsFound,
    OBATripStateCellTypeItinerary,
    OBATripStateCellTypeStartTime,
    OBATripStateCellTypeWalkToStop,
    OBATripStateCellTypeWalkToPlace,
    OBATripStateCellTypeStop,
    OBATripStateCellTypeDeparture,
    OBATripStateCellTypeRide,
    OBATripStateCellTypeArrival,
    OBATripStateCellTypeNone
} OBATripStateCellType;


@interface OBATripStateCellIndexPath : NSObject {
    OBATripStateCellType _type;
    NSUInteger _row;
}

- (id) initWithType:(OBATripStateCellType)type row:(NSUInteger)row;
+ (OBATripStateCellIndexPath*) indexPathWithType:(OBATripStateCellType)type row:(NSUInteger)row;
+ (OBATripStateCellIndexPath*) indexPathWithType:(OBATripStateCellType)type;

@property (nonatomic,readonly) OBATripStateCellType type;
@property (nonatomic,readonly) NSUInteger row;

@end
