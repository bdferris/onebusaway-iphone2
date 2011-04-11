typedef enum {
    OBATargetTimeTypeNow,
    OBATargetTimeTypeDepartBy,
    OBATargetTimeTypeArriveBy
} OBATargetTimeType;


@interface OBATargetTime : NSObject {
    
}

- (id) initWithType:(OBATargetTimeType)targetType time:(NSDate*)targetTime;

+ (OBATargetTime*) timeNow;
+ (OBATargetTime*) timeDepartBy:(NSDate*)targetTime;
+ (OBATargetTime*) timeArriveBy:(NSDate*)targetTime;

@property (nonatomic) OBATargetTimeType type;
@property (nonatomic,retain) NSDate * time;

@end
