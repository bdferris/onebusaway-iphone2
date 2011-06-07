#import "OBAAlarmViewController.h"
#import "OBAListSelectionViewController.h"

static const NSInteger kAlarmTimeOffsetValues[] = {0,1,2,3,4,5,6,7,8,9,10,15,20,30};


@interface OBAAlarmViewController (Private)

- (UITableViewCell*) createTitleCellForIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) createAlarmTimeOffsetCellForIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) createActionCellForIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView;

- (void) didSelectAlarmTimeOffsetRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) didSelectActionRowAtIndexPath:(NSIndexPath*)indexPath;

@end


@implementation OBAAlarmViewController

- (id) initWithAppContext:(OBAApplicationContext*)appContext tripState:(OBATripState*)tripState cellType:(OBATripStateCellType)cellType
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _appContext = [appContext retain];
        _tripState = [tripState retain];
        _cellType = cellType;
        
        switch (cellType) {
            case OBATripStateCellTypeItinerary:
            case OBATripStateCellTypeStartTime:
                _alarmType = OBAAlarmTypeStart;
                break;
            case OBATripStateCellTypeDeparture:
                _alarmType = OBAAlarmTypeDeparture;
                break;
            case OBATripStateCellTypeArrival:
                _alarmType = OBAAlarmTypeArrival;
                break;
            default:
                NSLog(@"Unsupported cell type for alarm: %d", _cellType);
                _alarmType = OBAAlarmTypeDeparture;
                break;
        }

        _cellFactory = [[OBATripStateTableViewCellFactory alloc] initWithAppContext:_appContext navigationController:self.navigationController tableView:self.tableView];
        
        _alarmSet = [_appContext.tripController isAlarmEnabledForType:_alarmType tripState:tripState];
        _alarmTimeOffset = [_appContext.tripController getAlarmTimeOffsetForType:_alarmType tripState:tripState];
        
        NSMutableArray * values = [[NSMutableArray alloc] init];
        [values addObject:@"No offset"];
        [values addObject:@"1 min early"];
        [values addObject:@"2 mins"];
        [values addObject:@"3 mins"];
        [values addObject:@"4 mins"];
        [values addObject:@"5 mins"];
        [values addObject:@"6 mins"];
        [values addObject:@"7 mins"];
        [values addObject:@"8 mins"];
        [values addObject:@"9 mins"];
        [values addObject:@"10 mins"];
        [values addObject:@"15 mins"];
        [values addObject:@"20 mins"];
        [values addObject:@"30 mins"];
        
        _alarmTimeOffsetLabels = values;
        
        self.navigationItem.title = _alarmSet ? @"Alarm Set" : @"Set Alarm";
        self.hidesBottomBarWhenPushed = TRUE;
    }
    return self;
}

- (void)dealloc
{
    [_appContext release];
    [_tripState release];
    [_cellFactory release];    
    [_alarmTimeOffsetLabels release];
    [super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if( section == 0 ) {
        switch (_cellType) {                
            case OBATripStateCellTypeStartTime:
                return _alarmSet ? @"Alarm set for your trip start:" : @"Set an alarm for your trip start:";
            case OBATripStateCellTypeDeparture:
                return _alarmSet ? @"Alarm set for your departure" : @"Set an alarm for your departure:";
            case OBATripStateCellTypeArrival:
                return _alarmSet ? @"Alarm set for your arrival:" : @"Set an alarm for your arrival:";
            default:
                return @"Alarm Notification";
        }
    }
    else if( section == 1 ) {
        return @"Alarm timing:";
    }
    else if( section == 3) {
        return @"Note: The alarm is NOT automatically adjusted if you change your current location.  Choosing a new itinerary resets any active alarms.";
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    switch (section) {
        case 0:
        case 1:
        case 2:
            return 1;
        case 3:
            return 0;
        default:
            break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {            
        case 0:
            return [self createTitleCellForIndexPath:indexPath tableView:tableView];
        case 1:
            return [self createAlarmTimeOffsetCellForIndexPath:indexPath tableView:tableView];
        case 2:
            return [self createActionCellForIndexPath:indexPath tableView:tableView];
        default:
            break;
    }
    
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            break;
        case 1:
            [self didSelectAlarmTimeOffsetRowAtIndexPath:indexPath];
            break;
        case 2:
            [self didSelectActionRowAtIndexPath:indexPath];
            break;
        default:
            break;
    }
}

@end



@implementation OBAAlarmViewController (Private)

- (UITableViewCell*) createTitleCellForIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView {

    switch (_cellType) {
        case OBATripStateCellTypeItinerary:
        case OBATripStateCellTypeStartTime:
            return [_cellFactory createCellForStartTrip:_tripState includeDetail:FALSE];
        case OBATripStateCellTypeDeparture:
            return [_cellFactory createCellForVehicleDeparture:_tripState.departure itinerary:nil includeDetail:FALSE selected:FALSE];
        case OBATripStateCellTypeArrival:
            return [_cellFactory createCellForVehicleArrival:_tripState.arrival itinerary:nil includeDetail:FALSE selected:FALSE];
        default:
            break;
    }
    
    return nil;
}

- (UITableViewCell*) createAlarmTimeOffsetCellForIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView {

    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    
    NSInteger mins = _alarmTimeOffset / 60;

    if( mins == 0 ) {
        cell.textLabel.text = @"Configure alarm timing";
    }
    else if( mins < 0 ) {
        mins = -mins;
        NSString * minsLabel = (mins  == 1) ? @"min" : @"mins";
        cell.textLabel.text = [NSString stringWithFormat:@"Ring %d %@ late",mins, minsLabel];
    }
    else if( _alarmTimeOffset > 0 ) {
        NSString * minsLabel = (mins  == 1) ? @"min" : @"mins";
        cell.textLabel.text = [NSString stringWithFormat:@"Ring alarm %d %@ early",mins, minsLabel];
    }

    if( _alarmSet ) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (UITableViewCell*) createActionCellForIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView {

    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    
    if( _alarmSet ) {
        cell.textLabel.text = @"Delete this alarm";
        cell.textLabel.textColor = [UIColor redColor];
    }
    else {
        cell.textLabel.text = @"Set alarm";
        cell.textLabel.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1.0];
    }
    
    return cell;
}

- (void) didSelectAlarmTimeOffsetRowAtIndexPath:(NSIndexPath*)indexPath {
    
    if( _alarmSet ) 
        return;
    
    NSUInteger index = 1;
    NSInteger offset = _alarmTimeOffset / 60;
    
    for( NSUInteger i=0; i<[_alarmTimeOffsetLabels count]; i++) {
        
        if (offset == kAlarmTimeOffsetValues[i]) {
            index = i;
            break;
        }
    }
    
    NSIndexPath * path = [NSIndexPath indexPathForRow:index inSection:0];
    OBAListSelectionViewController * vc = [[OBAListSelectionViewController alloc] initWithValues:_alarmTimeOffsetLabels selectedIndex:path];
    vc.target = self;
    vc.action = @selector(onAlarmOffsetTimeSelection:);
    
    [self.navigationController pushViewController:vc animated:TRUE];
    [vc release];
}

- (void) didSelectActionRowAtIndexPath:(NSIndexPath*)indexPath {
    [_appContext.tripController updateAlarm:!_alarmSet withType:_alarmType tripState:_tripState alarmTimeOffset:_alarmTimeOffset];
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (void) onAlarmOffsetTimeSelection:(NSIndexPath*)indexPath {
    if( indexPath.row < [_alarmTimeOffsetLabels count] ) {
        _alarmTimeOffset = kAlarmTimeOffsetValues[indexPath.row] * 60;
        [self.tableView reloadData];
    }
}

@end

