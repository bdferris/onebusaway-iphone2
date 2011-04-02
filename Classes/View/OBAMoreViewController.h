#import "OBAApplicationContext.h"


@interface OBAMoreViewController : UITableViewController {
    OBAApplicationContext * _appContext;
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext;

@end
