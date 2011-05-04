#import "OBAApplicationContext.h"
#import "OBATripStateTableViewCellFactory.h"
#import "OBATripController.h"


@interface OBAPickTripViewController : UITableViewController <OBATripControllerDelegate> {
    OBAApplicationContext * _appContext;
    OBATripStateTableViewCellFactory * _tripStateTableViewCellFactory;
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext;

@end
