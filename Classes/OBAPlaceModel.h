#import "OBAApplicationContext.h"


@interface OBAPlaceModel : NSObject <TTModel> {
    OBAApplicationContext * _appContext;
    NSMutableArray *_delegates;
    NSMutableArray *_places;
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext;

- (void)search:(NSString *)text;

@property (nonatomic,readonly) NSArray * places;
           
@end
