#import "OBAApplicationContext.h"
#import "OBATripStateTableViewCellFactory.h"


@interface OBAPickTripViewController : UITableViewController {
    OBAApplicationContext * _appContext;
    OBATripStateTableViewCellFactory * _tripStateTableViewCellFactory;
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext;

@end
