#import "OBAApplicationContext.h"
#import "OBAAlarmTableViewCellFactory.h"
#import "OBATripState.h"


@interface OBAStartTripViewController : UITableViewController {
    OBAApplicationContext * _appContext;
    OBAAlarmTableViewCellFactory * _alarmTableViewCellFactory;
    OBATripState * _tripState;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext tripState:(OBATripState*)tripState;

@end
