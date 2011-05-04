#import "OBAAlarmTableViewCellFactory.h"
#import "OBALabelAndSwitchTableViewCell.h"
#import "OBAListSelectionViewController.h"

static const NSInteger kAlarmTimeOffsetValues[] = {0,1,2,3,4,5,6,7,8,9,10,15,20,30};

@implementation OBAAlarmTableViewCellFactory

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext tripState:(OBATripState*)tripState tableViewController:(UITableViewController*)controller {

    self = [super init];
    if (self) { 
        _appContext = [appContext retain];
        _tripState = [tripState retain];
        _tableViewController = [controller retain];
        
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
    }
    return self;
}

- (void) dealloc {
    [_appContext release];
    [_tripState release];
    [_tableViewController release];
    [_alarmTimeOffsetLabels release];
    [super dealloc];
}

- (NSInteger) numberOfRowsInSection {
    return 2;
}

- (UITableViewCell*) cellForRowAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView {
    
    if (indexPath.row == 0) {
        OBALabelAndSwitchTableViewCell* cell = [OBALabelAndSwitchTableViewCell getOrCreateCellForTableView:tableView];
        UILabel * label = cell.label;
        label.text = @"Alarm set:";
        
        UISwitch * toggleSwitch = cell.toggleSwitch;
        [toggleSwitch addTarget:self action:@selector(onToggleSwitch:) forControlEvents:UIControlEventValueChanged];
        
        OBATripController * tripController = _appContext.tripController;
        toggleSwitch.on = [tripController isAlarmEnabledForTripState:_tripState];
        
        return cell;
    }
    else if (indexPath.row == 1) {
        
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if( _alarmTimeOffset == 0 ) {
            cell.textLabel.text = @"Configure alarm timing";
        }
        else if( _alarmTimeOffset < 0 ) {
            cell.textLabel.text = [NSString stringWithFormat:@"Alarm %d mins late",(-_alarmTimeOffset)];
        }
        else if( _alarmTimeOffset > 0 ) {
            cell.textLabel.text = [NSString stringWithFormat:@"Alarm %d mins early",_alarmTimeOffset];
        }
        return cell;
    }
    
    return nil;
}

- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    if (indexPath.row == 1) {
        NSUInteger index = 0;
        for( NSUInteger i=0; i<[_alarmTimeOffsetLabels count]; i++) {
            if (_alarmTimeOffset == kAlarmTimeOffsetValues[i]) {
                index = i;
                break;
            }
        }        
        NSIndexPath * path = [NSIndexPath indexPathForRow:index inSection:0];
        OBAListSelectionViewController * vc = [[OBAListSelectionViewController alloc] initWithValues:_alarmTimeOffsetLabels selectedIndex:path];
        vc.target = self;
        vc.action = @selector(onAlarmOffsetTimeSelection:);
        
        [_tableViewController.navigationController pushViewController:vc animated:TRUE];
        [vc release];
    }
}
     
- (IBAction) onToggleSwitch:(id)sender {

    UISwitch * toggleSwitch = sender;

    OBATripController * tripController = _appContext.tripController;
    [tripController updateAlarm:toggleSwitch.on forTripState:_tripState alarmTimeOffset:_alarmTimeOffset];
}

- (void) onAlarmOffsetTimeSelection:(NSIndexPath*)indexPath {
    _alarmTimeOffset = kAlarmTimeOffsetValues[indexPath.row];
    [_tableViewController.tableView reloadData];
}

@end
