#import "OBAApplicationContext.h"
#import "OBATripState.h"
#import "OBATripStateTableViewCellFactory.h"


@interface OBAAlarmViewController : UITableViewController {
    OBAApplicationContext * _appContext;
    OBATripState * _tripState;
    OBATripStateCellType _cellType;
    OBATripStateTableViewCellFactory * _cellFactory;
    BOOL _alarmSet;
    NSInteger _alarmTimeOffset;
    NSArray * _alarmTimeOffsetLabels;
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext tripState:(OBATripState*)tripState cellType:(OBATripStateCellType)cellType;

@end
