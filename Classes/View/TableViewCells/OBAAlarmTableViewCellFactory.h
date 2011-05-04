#import "OBAApplicationContext.h"
#import "OBATripState.h"


@interface OBAAlarmTableViewCellFactory : NSObject {
    OBAApplicationContext * _appContext;
    OBATripState * _tripState;
    UITableViewController * _tableViewController;
    UITableView * _tableView;
    NSInteger _alarmTimeOffset;
    NSArray * _alarmTimeOffsetLabels;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext tripState:(OBATripState*)tripState tableViewController:(UITableViewController*)controller;
- (NSInteger) numberOfRowsInSection;
- (UITableViewCell*) cellForRowAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView;
- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end
