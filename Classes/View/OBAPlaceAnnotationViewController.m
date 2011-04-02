#import "OBAPlaceAnnotationViewController.h"
#import "OBAEditBookmarkViewController.h"


typedef enum {
    OBAPlaceAnnotationViewControllerSectionTitle,
    OBAPlaceAnnotationViewControllerSectionActions,
    OBAPlaceAnnotationViewControllerSectionNone
} OBAPlaceAnnotationViewControllerSection;


@interface OBAPlaceAnnotationViewController (Private) 

- (OBAPlaceAnnotationViewControllerSection) sectionForIndex:(NSInteger)sectionIndex;
- (UITableViewCell *) titleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (UITableViewCell *) actionCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end


@implementation OBAPlaceAnnotationViewController

- (id)initWithAppContext:(OBAApplicationContext*)appContext place:(OBAPlace*)place
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _appContext = [appContext retain];
        _place = [place retain];
        
        self.navigationItem.title = @"Place";
        
    }
    return self;
}

- (void)dealloc
{
    [_appContext release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OBAPlaceAnnotationViewControllerSection sectionType = [self sectionForIndex:section];
    switch (sectionType) {
        case OBAPlaceAnnotationViewControllerSectionTitle:
            return 1;
        case OBAPlaceAnnotationViewControllerSectionActions:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OBAPlaceAnnotationViewControllerSection sectionType = [self sectionForIndex:indexPath.section];
    switch (sectionType) {
        case OBAPlaceAnnotationViewControllerSectionTitle:
            return [self titleCellForRowAtIndexPath:indexPath tableView:tableView];
        case OBAPlaceAnnotationViewControllerSectionActions:
            return [self actionCellForRowAtIndexPath:indexPath tableView:tableView];
        default:
            return nil;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OBAPlaceAnnotationViewControllerSection sectionType = [self sectionForIndex:indexPath.section];
    switch (sectionType) {
        case OBAPlaceAnnotationViewControllerSectionActions: {
            if( indexPath.row == 0 ) {
                OBAPlace * place = [OBAPlace placeWithPlace:_place];
                OBAEditBookmarkViewController * vc = [[OBAEditBookmarkViewController alloc] initWithApplicationContext:_appContext bookmark:place editType:OBABookmarkEditNew];
                [self.navigationController pushViewController:vc animated:TRUE];
                [vc release];
            }
            break;
        }
        default:
            break;
    }

    
}

@end


@implementation OBAPlaceAnnotationViewController (Private) 

- (OBAPlaceAnnotationViewControllerSection) sectionForIndex:(NSInteger)sectionIndex {
    switch(sectionIndex) {
        case 0:
            return OBAPlaceAnnotationViewControllerSectionTitle;
        case 1:
            return OBAPlaceAnnotationViewControllerSectionActions;
    }
    return OBAPlaceAnnotationViewControllerSectionNone;
}

- (UITableViewCell *) titleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"TitleCell"];
    cell.textLabel.text = _place.name;
    return cell;
}

- (UITableViewCell *) actionCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"ActionCell"];    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = @"Add Bookmark";
    return cell;
}

@end

