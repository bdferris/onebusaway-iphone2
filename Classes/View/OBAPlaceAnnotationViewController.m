#import "OBAPlaceAnnotationViewController.h"
#import "OBAEditBookmarkViewController.h"
#import "OBATripQuery.h"
#import "OBAPlanTripViewController.h"


typedef enum {
    OBAPlaceAnnotationViewControllerSectionTitle,
    OBAPlaceAnnotationViewControllerSectionDirections,
    OBAPlaceAnnotationViewControllerSectionActions,
    OBAPlaceAnnotationViewControllerSectionNone
} OBAPlaceAnnotationViewControllerSection;


@interface OBAPlaceAnnotationViewController (Private) 

- (OBAPlaceAnnotationViewControllerSection) sectionForIndex:(NSInteger)sectionIndex;
- (UITableViewCell *) titleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (UITableViewCell *) directionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (UITableViewCell *) actionCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

- (void) didSelectDirectionsRowAtIndexPath:(NSIndexPath *)indexPath;
- (void) didSelectActionsRowAtIndexPath:(NSIndexPath *)indexPath;

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger c = 2; // Title + Directions
    
    if (! _place.isBookmark) {
        c++;
    }
    
    return c;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OBAPlaceAnnotationViewControllerSection sectionType = [self sectionForIndex:section];
    switch (sectionType) {
        case OBAPlaceAnnotationViewControllerSectionTitle:
            return 1;
        case OBAPlaceAnnotationViewControllerSectionDirections:
            return 2;
        case OBAPlaceAnnotationViewControllerSectionActions: {
            NSInteger c = 1;
            if (_place.isDroppedPin) {
                c++;
            }
            return c;
        }
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
        case OBAPlaceAnnotationViewControllerSectionDirections:
            return [self directionsCellForRowAtIndexPath:indexPath tableView:tableView];
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
        case OBAPlaceAnnotationViewControllerSectionDirections:
            [self didSelectDirectionsRowAtIndexPath:indexPath];
            break;
        case OBAPlaceAnnotationViewControllerSectionActions:
            [self didSelectActionsRowAtIndexPath:indexPath];
            break;
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
            return OBAPlaceAnnotationViewControllerSectionDirections;            
        case 2:
            return OBAPlaceAnnotationViewControllerSectionActions;
    }
    return OBAPlaceAnnotationViewControllerSectionNone;
}

- (UITableViewCell *) titleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"TitleCell"];
    cell.textLabel.text = _place.name;
    return cell;
}

- (UITableViewCell *) directionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"DirectionsCell"];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Directions from";
    }
    else {
        cell.textLabel.text = @"Directions to";
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.textLabel.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1.0];
    
    return cell;
}

- (UITableViewCell *) actionCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"ActionCell"];    

    if (indexPath.row == 0) {
        cell.textLabel.text = @"Add Bookmark";
    }
    else if (indexPath.row == 1) {
        cell.textLabel.text = @"Delete Pin";
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.textLabel.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1.0];

    return cell;
}

- (void) didSelectDirectionsRowAtIndexPath:(NSIndexPath *)indexPath {

    OBAPlace * currentLocation = [OBAPlace placeWithCurrentLocation];
    OBAModelDAO * modelDao = _appContext.modelDao;
    OBATripQueryOptimizeForType optimizeFor = modelDao.defaultTripQueryOptimizeForType;
    
    switch (indexPath.row) {
        case 0: {
            OBATripQuery * query = [[OBATripQuery alloc] initWithPlaceFrom:_place placeTo:currentLocation time:[OBATargetTime timeNow] optimizeFor:optimizeFor];
            OBAPlanTripViewController * vc = [[OBAPlanTripViewController alloc] initWithAppContext:_appContext];
            [vc setTripQuery:query];
            [self.navigationController pushViewController:vc animated:TRUE];
            [query release];
            [vc release];
            break;
        }
        case 1: {
            OBATripQuery * query = [[OBATripQuery alloc] initWithPlaceFrom:currentLocation placeTo:_place time:[OBATargetTime timeNow] optimizeFor:optimizeFor];
            OBAPlanTripViewController * vc = [[OBAPlanTripViewController alloc] initWithAppContext:_appContext];
            [vc setTripQuery:query];
            [self.navigationController pushViewController:vc animated:TRUE];
            [query release];
            [vc release];
            break;
        }
        default:
            break;
    }
}

- (void) didSelectActionsRowAtIndexPath:(NSIndexPath *)indexPath {
    if( indexPath.row == 0 ) {
        OBAPlace * place = [OBAPlace placeWithPlace:_place];
        OBAEditBookmarkViewController * vc = [[OBAEditBookmarkViewController alloc] initWithApplicationContext:_appContext bookmark:place editType:OBABookmarkEditNew];        
        [vc setOnSuccessTarget:self action:@selector(onBookmarkSuccess:)];
        vc.popToRootOnCompletion = TRUE;
        [self.navigationController pushViewController:vc animated:TRUE];
        [vc release];
    }
    else if (indexPath.row == 1) {
        [_appContext.modelDao removeDroppedPin:_place];
        [self.navigationController popToRootViewControllerAnimated:TRUE];
    }
}

- (void) onBookmarkSuccess:(id)sender {
    if (_place.isDroppedPin) {
        [_appContext.modelDao removeDroppedPin:_place];
    }
}

@end

