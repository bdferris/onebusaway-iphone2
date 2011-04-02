#import "OBAPlaceModel.h"
#import "OBAApplicationContext.h"


@interface OBAPlaceDataSource : TTSectionedDataSource {
    OBAPlaceModel * _placeModel;
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext;

@end
