#import "OBAApplicationContext.h"
#import "OBAPlace.h"


@interface OBAPlaceAnnotationViewController : UITableViewController {
    OBAApplicationContext * _appContext;
    OBAPlace * _place;
}

- (id)initWithAppContext:(OBAApplicationContext*)appContext place:(OBAPlace*)place;

@end
