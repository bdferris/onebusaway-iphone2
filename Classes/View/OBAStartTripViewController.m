#import "OBAStartTripViewController.h"


@implementation OBAStartTripViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext tripState:(OBATripState*)tripState {

    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _appContext = [appContext retain];
        _alarmTableViewCellFactory = [[OBAAlarmTableViewCellFactory alloc] initWithApplicationContext:appContext tripState:tripState tableViewController:self];
        _tripState = [tripState retain];
    }
    return self;
}

- (void)dealloc {
    [_appContext release];
    [_alarmTableViewCellFactory release];
    [_tripState release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if( section == 0 )
        return @"Alarm Notification";
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if( section == 0 ) {
        return [_alarmTableViewCellFactory numberOfRowsInSection];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( indexPath.section == 0 ) {
        return [_alarmTableViewCellFactory cellForRowAtIndexPath:indexPath tableView:tableView];
    }
                
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( indexPath.section == 0 ) {
        [_alarmTableViewCellFactory didSelectRowAtIndexPath:indexPath tableView:tableView];
    }
}

@end
