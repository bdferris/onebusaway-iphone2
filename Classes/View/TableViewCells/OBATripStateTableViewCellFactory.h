#import "OBAApplicationContext.h"
#import "OBATripState.h"


@interface OBATripStateTableViewCellFactory : NSObject {
    OBAApplicationContext * _appContext;
    UINavigationController * _navigationController;
    UITableView * _tableView;
    NSDateFormatter * _timeFormatter;
    NSDictionary * _directions;
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext navigationController:(UINavigationController*)navigationController tableView:(UITableView*)tableView;

- (NSInteger) getNumberOfRowsForTripState:(OBATripState*)state;
- (UITableViewCell*) getCellForState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath;
- (void) didSelectRowForState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath;

@end
