#import "OBAPickTripViewController.h"
#import "OBAReportProblemWithPlannedTripViewController.h"


@implementation OBAPickTripViewController

- (id) initWithAppContext:(OBAApplicationContext*)appContext
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _appContext = [appContext retain];
    }
    return self;
}

- (void)dealloc
{
    [_tripStateTableViewCellFactory release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tripStateTableViewCellFactory = [[OBATripStateTableViewCellFactory alloc] initWithAppContext:_appContext navigationController:self.navigationController tableView:self.tableView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _appContext.tripController.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _appContext.tripController.delegate = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray * itineraries = _appContext.tripController.itineraries;
    return [itineraries count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray * itineraries = _appContext.tripController.itineraries;
    if( [itineraries count] == 0 ) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"NoItineraries"];
        cell.textLabel.text = @"No trips found";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        return cell;
    }
    
    if ([itineraries count] == indexPath.row) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"NoItineraries"];
        cell.textLabel.text = @"Missing a trip?";
        cell.textLabel.font = [UIFont systemFontOfSize:17.0];
        cell.textLabel.textAlignment = UITextAlignmentLeft;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        return cell;
    }
    else {
        OBAItineraryV2 * itinerary = [itineraries objectAtIndex:indexPath.row];
        return [_tripStateTableViewCellFactory createCellForTripSummary:itinerary];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray * itineraries = _appContext.tripController.itineraries;
    if ([itineraries count] == 0) {
        return;
    }
    
    if ([itineraries count] == indexPath.row) {
        OBAReportProblemWithPlannedTripViewController * vc = [[OBAReportProblemWithPlannedTripViewController alloc] initWithApplicationContext:_appContext];
        [self.navigationController pushViewController:vc animated:TRUE];
        [vc release];         
    }
    else {
        [self.navigationController popToRootViewControllerAnimated:TRUE];
        OBAItineraryV2 * itinerary = [itineraries objectAtIndex:indexPath.row];
        [_appContext.tripController selectItinerary:itinerary];
    }
}

#pragma mark OBATripControllerDelegate

-(void) chooseFromItineraries:(NSArray*)itineraries {
    [self.tableView reloadData];
}

-(void) refreshingItineraries {
    self.navigationItem.title = @"Updating...";
}

-(void) refreshingItinerariesCompleted {
    self.navigationItem.title = nil;
}

-(void) refreshingItinerariesFailed:(NSError*)error {
    self.navigationItem.title = @"Error updating...";
}

@end
