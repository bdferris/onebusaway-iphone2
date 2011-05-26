/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBABookmarksViewController.h"
#import "OBALogger.h"
#import "OBAEditBookmarkViewController.h"
#import "OBAPlace.h"
#import "OBACurrentTravelModeState.h"
#import "OBAPlacePresentation.h"


@interface OBABookmarksViewController (Private)

- (NSArray*) createToolbarItemsWithButtons:(UISegmentedControl*)segmented;

- (UITableViewCell *)bookmarkCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (UITableViewCell *)recentCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (UITableViewCell *)contactCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (UITableViewCell *)currentLocationCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

- (void)didSelectBookmarkRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (void)didSelectRecentRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (void)didSelectContactRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (void)didSelectCurrentLocationRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;


- (void) refreshData;
- (void) abortEditing;

- (IBAction) onCancel:(id)sender;
- (IBAction) onEditButton:(id)sender;
- (IBAction) onClearRecentPlaces:(id)sender;
- (IBAction) onBookmarkTypeChanged:(id)sender;

@end


@implementation OBABookmarksViewController

@synthesize appContext = _appContext;
@synthesize delegate;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext { 
    self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		_appContext = [appContext retain];
        _includeCurrentLocation = FALSE;
        _mode = OBABookmarksViewControllerModeBookmarks;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        self.hidesBottomBarWhenPushed = FALSE;
        self.tableView.allowsSelectionDuringEditing = TRUE;
	}
	return self;
}

- (void)dealloc {
	[_appContext release];
    [_currentLocations release];
	[_bookmarks release];
    [_recents release];
    [_segmented release];
    [_bookmarkEditButton release];
    [_recentClearButton release];
    [_peoplePicker release];
    [_geocoder release];
    [super dealloc];
}


+ (void) showBookmarksViewControllerWithAppContext:(OBAApplicationContext*)appContext parent:(UINavigationController*)parent delegate:(id<OBABookmarksViewControllerDelegate>)delegate includeCurrentLocation:(BOOL)includeCurrentLocation {

    OBABookmarksViewController * vc = [[OBABookmarksViewController alloc] initWithApplicationContext:appContext];
    vc.delegate = delegate;
    vc.includeCurrentLocation = includeCurrentLocation;
    
    UINavigationController * nc =[[UINavigationController alloc] initWithRootViewController:vc];
    [parent presentModalViewController:nc animated:TRUE];
    
    [nc setToolbarHidden:FALSE];
    [nc release];
    [vc release];
}


- (BOOL) includeCurrentLocation {
    return _includeCurrentLocation;
}

- (void) setIncludeCurrentLocation:(BOOL)includeCurrentLocation {
    _includeCurrentLocation = includeCurrentLocation;
    [self.tableView reloadData];
}

- (OBABookmarksViewControllerMode) mode {
    return _mode;
}

- (void) setMode:(OBABookmarksViewControllerMode)mode {
    
    BOOL wasContacts = _mode == OBABookmarksViewControllerModeContacts;
    BOOL isContacts = mode == OBABookmarksViewControllerModeContacts;
    
    if( _mode == OBABookmarksViewControllerModeBookmarks && self.editing) {
        self.editing = FALSE;
        [self.tableView setEditing:FALSE animated:FALSE];
        
        _bookmarkEditButton.title = @"Edit";
        _bookmarkEditButton.style = UIBarButtonItemStyleBordered;
    }
    
    _mode = mode;

    switch (_mode) {
        case OBABookmarksViewControllerModeBookmarks: {
            self.navigationItem.title = @"Bookmarks";
            _segmented.selectedSegmentIndex = 0;
            self.navigationItem.leftBarButtonItem = _bookmarkEditButton;
            break;
        }
        case OBABookmarksViewControllerModeRecent: {
            self.navigationItem.title = @"Recent";
            _segmented.selectedSegmentIndex = 1;
            self.navigationItem.leftBarButtonItem = _recentClearButton;
            break;
        }
        case OBABookmarksViewControllerModeContacts: {
            self.navigationItem.title = @"Contacts";
            self.navigationItem.leftBarButtonItem = nil;
            _segmented.selectedSegmentIndex = 2;
            
            if (! wasContacts) {
                [self.navigationController presentModalViewController:_peoplePicker animated:FALSE];
            }
            
            break;
        }
    }
    
    /**
     * If we were in Contacts mode, it means the PeoplePicker VC is currently being presented modally and we need to hide it.
     */
    if (wasContacts && !isContacts) {
        [_peoplePicker dismissModalViewControllerAnimated:FALSE];
    }
    
    [self.tableView reloadData];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem * cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
    self.navigationItem.rightBarButtonItem = cancelItem;
    [cancelItem release];

    _bookmarkEditButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(onEditButton:)];
    _recentClearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStyleBordered target:self action:@selector(onClearRecentPlaces:)];
    
    NSArray * items = [NSArray arrayWithObjects:@"Bookmarks",@"Recent",@"Contacts", nil];
    
    _segmented = [[UISegmentedControl alloc] initWithItems:items];
    _segmented.segmentedControlStyle = UISegmentedControlStyleBar;
    _segmented.selectedSegmentIndex = 0;
    [_segmented addTarget:self action:@selector(onBookmarkTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [_segmented sizeToFit];
    
    self.toolbarItems = [self createToolbarItemsWithButtons:_segmented];
    
    _peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
    _peoplePicker.peoplePickerDelegate = self;
    _peoplePicker.delegate = self;
    _peoplePicker.hidesBottomBarWhenPushed = FALSE;
    [_peoplePicker setToolbarHidden:FALSE animated:FALSE];
    _peoplePicker.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonAddressProperty]];
    
    _geocoder = [[OBAGeocoderController alloc] initWithAppContext:_appContext navigationController:self.navigationController];
    _geocoder.delegate = self;
    
    self.mode = OBABookmarksViewControllerModeBookmarks;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	// We reload the table here in case we are coming back from the user editing the label for bookmark
	[self refreshData];
    
    if (_includeCurrentLocation) {
        OBACurrentTravelModeController * controller = _appContext.currentTravelModeController;
        controller.delegate = self;
    }
    
	[self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_includeCurrentLocation) {
        OBACurrentTravelModeController * controller = _appContext.currentTravelModeController;
        controller.delegate = nil;
    }
}
     


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {	
    switch (_mode) {
        case OBABookmarksViewControllerModeBookmarks: {
            int count = [_bookmarks count];
            if( _includeCurrentLocation && ! self.editing)
                count += [_currentLocations count];
            if( count == 0 )
                count++;
            return count;
        }
        case OBABookmarksViewControllerModeRecent: {
            int count = [_recents count];
            if( _includeCurrentLocation && ! self.editing)
                count += [_currentLocations count];
            if( count == 0 )
                count++;
            return count;
        }            
        case OBABookmarksViewControllerModeContacts:
            return 0;
        default:
            return 0;
    }
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    switch (_mode) {
        case OBABookmarksViewControllerModeBookmarks:
            return [self bookmarkCellForRowAtIndexPath:indexPath tableView:tableView];
        case OBABookmarksViewControllerModeRecent:
            return [self recentCellForRowAtIndexPath:indexPath tableView:tableView];
        case OBABookmarksViewControllerModeContacts:
            return [self contactCellForRowAtIndexPath:indexPath tableView:tableView];

    }
    
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
    switch (_mode) {
        case OBABookmarksViewControllerModeBookmarks:
            [self didSelectBookmarkRowAtIndexPath:indexPath tableView:tableView];
            return;
        case OBABookmarksViewControllerModeRecent:
            [self didSelectRecentRowAtIndexPath:indexPath tableView:tableView];
            return;
        case OBABookmarksViewControllerModeContacts:
            [self didSelectContactRowAtIndexPath:indexPath tableView:tableView];
            return;
    }
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath  {
	
	OBAModelDAO * modelDao = _appContext.modelDao;
	OBAPlace * bookmark = [_bookmarks objectAtIndex:(indexPath.row)];
	NSError * error = nil;
	[modelDao removeBookmark:bookmark error:&error];
	if( error ) 
		OBALogSevereWithError(error,@"Error removing bookmark");
	[self refreshData];
	
	if( [_bookmarks count] > 0 ) {
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
						 withRowAnimation:UITableViewRowAnimationFade];
	}
	else {
		[self performSelector:@selector(abortEditing) withObject:nil afterDelay:0.1];
	}
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

-(void) tableView: (UITableView *) tableView moveRowAtIndexPath: (NSIndexPath *) oldPath toIndexPath:(NSIndexPath *) newPath {
	
	OBAModelDAO * modelDao = _appContext.modelDao;
	NSError * error = nil;
	[modelDao moveBookmark:oldPath.row to: newPath.row error:&error];
	if( error ) 
		OBALogSevereWithError(error,@"Error moving bookmark");
	[self refreshData];
}

#pragma mark OBACurrentTravelModeDelegate

- (void) didUpdateCurrentTravelModes:(NSArray*)modes controller:(OBACurrentTravelModeController*)controller {
    
}

#pragma mark ABPeoplePickerNavigationControllerDelegate 

// Called after the user has pressed cancel
// The delegate is responsible for dismissing the peoplePicker
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [peoplePicker dismissModalViewControllerAnimated:FALSE];
    [self dismissModalViewControllerAnimated:TRUE];
}

// Called after a person has been selected by the user.
// Return YES if you want the person to be displayed.
// Return NO  to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    return TRUE;
}

// Called after a value has been selected by the user.
// Return YES if you want default action to be performed.
// Return NO to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    
    if (property == kABPersonAddressProperty) {
        
        ABMultiValueRef multi = ABRecordCopyValue(person, property);
        NSArray *theArray = [(id)ABMultiValueCopyArrayOfAllValues(multi) autorelease];
        
        // Figure out which values we want and store the index.
        const NSUInteger theIndex = ABMultiValueGetIndexForIdentifier(multi, identifier);
        
        NSDictionary *theDict = [theArray objectAtIndex:theIndex];
        
        OBAPlace * place = [OBAPlacePresentation getAddressBookPersonAsPlace:person withAddressRecord:theDict];
        
        [_geocoder geocodeAddress:place.address withContext:place];
        
        CFRelease(multi);
    }
    
    [peoplePicker dismissModalViewControllerAnimated:FALSE];
    [self dismissModalViewControllerAnimated:TRUE];

    return FALSE;
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {

    NSArray * items = [NSArray arrayWithObjects:@"Bookmarks",@"Recent",@"Contacts", nil];
    
    UISegmentedControl * segmented = [[UISegmentedControl alloc] initWithItems:items];
    segmented.segmentedControlStyle = UISegmentedControlStyleBar;
    segmented.selectedSegmentIndex = 2;
    [segmented addTarget:self action:@selector(onBookmarkTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [segmented sizeToFit];

    viewController.toolbarItems = [self createToolbarItemsWithButtons:segmented];
    viewController.hidesBottomBarWhenPushed = FALSE;
    [navigationController setToolbarHidden:FALSE animated:FALSE];
    
    [segmented release];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    viewController.hidesBottomBarWhenPushed = FALSE;
}

#pragma mark OBAGeocoderControllerDelegate

-(void) handleGeocoderPlace:(OBAPlace*)place context:(id)context {
    OBAPlace * contact = (OBAPlace*)context;
    contact.location = place.location;
    [self.delegate placeBookmarkSelected:contact];
}

-(void) handleGeocoderError {
    
}

-(void) handleGeocoderNoResultFound {
    
}

@end



@implementation OBABookmarksViewController (Private)

- (NSArray*) createToolbarItemsWithButtons:(UISegmentedControl*)segmented {
    
    UIBarButtonItem * itemA = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem * itemB = [[UIBarButtonItem alloc] initWithCustomView:segmented];
    UIBarButtonItem * itemC = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];    
    
    NSArray * toolbarItems = [NSArray arrayWithObjects:itemA,itemB,itemC,nil];
    
    [itemA release];
    [itemB release];
    [itemC release];
    
    return toolbarItems;
}

- (UITableViewCell *)bookmarkCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {

    NSInteger offset = 0;
    
    if( _includeCurrentLocation && ! self.editing ) {        
        NSInteger locationCount = [_currentLocations count];
        if( indexPath.row < locationCount )
            return [self currentLocationCellForRowAtIndexPath:indexPath tableView:tableView];
        offset = locationCount;
    }
    
    if( [_bookmarks count] == 0 ) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.textLabel.text = @"No bookmarks set";
        cell.textLabel.textAlignment = UITextAlignmentLeft;		
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    OBAPlace * bookmark = [_bookmarks objectAtIndex:(indexPath.row - offset)];
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.textLabel.text = bookmark.name;
    cell.textLabel.textAlignment = UITextAlignmentLeft;		
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    return cell;
}

- (UITableViewCell *)recentCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {

    NSInteger offset = 0;
    
    if( _includeCurrentLocation && ! self.editing) {        
        NSInteger locationCount = [_currentLocations count];
        if( indexPath.row < locationCount )
            return [self currentLocationCellForRowAtIndexPath:indexPath tableView:tableView];
        offset = locationCount;        
    }
    
    if( [_recents count] == 0 ) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        cell.textLabel.text = @"No recent searches";
        cell.textLabel.textAlignment = UITextAlignmentLeft;		
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    OBAPlace * place = [_recents objectAtIndex:(indexPath.row - offset)];
    UITableViewCellStyle style = place.address != nil ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault;
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:style];
    cell.textLabel.text = place.name;
    if (place.address)
        cell.detailTextLabel.text = place.address;
    cell.textLabel.textAlignment = UITextAlignmentLeft;		
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    return cell;
}

- (UITableViewCell *)contactCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView { 
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.textLabel.text = @"No contacts";
    cell.textLabel.textAlignment = UITextAlignmentLeft;		
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UITableViewCell *)currentLocationCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {

    OBACurrentTravelModeState * state = [_currentLocations objectAtIndex:indexPath.row];
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle cellId:@"CurrentLocationTableViewCell"];
    
    cell.textLabel.text = @"Current Location";
    cell.textLabel.textColor = [UIColor blueColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;

    cell.detailTextLabel.text = state.label;
    cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
    
    cell.accessoryType = UITableViewCellAccessoryNone;		
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    return cell;
}

- (void)didSelectBookmarkRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {

    NSInteger offset = 0;
    
    if( _includeCurrentLocation && ! self.editing) {
        NSInteger locationCount = [_currentLocations count];
        if( indexPath.row < locationCount ) {
            [self didSelectCurrentLocationRowAtIndexPath:indexPath tableView:tableView];
            return; 
        }
        offset = locationCount;
    }
    
	if( [_bookmarks count] == 0 )
		return;
	
	OBAPlace * bookmark = [_bookmarks objectAtIndex:(indexPath.row-offset)];
	
	if( self.tableView.editing ) {
		OBAEditBookmarkViewController * vc = [[OBAEditBookmarkViewController alloc] initWithApplicationContext:_appContext bookmark:bookmark editType:OBABookmarkEditExisting];
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
	else {
        [self.delegate placeBookmarkSelected:bookmark];
        [self dismissModalViewControllerAnimated:TRUE];
	}
}

- (void)didSelectRecentRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {

    NSInteger offset = 0;
    
    if( _includeCurrentLocation && ! self.editing) {
        NSInteger locationCount = [_currentLocations count];
        if( indexPath.row < locationCount ) {
            [self didSelectCurrentLocationRowAtIndexPath:indexPath tableView:tableView];
            return; 
        }
        offset = locationCount;
    }
    
	if( [_recents count] == 0 )
		return;
	
	OBAPlace * place = [_recents objectAtIndex:(indexPath.row-offset)];
	
    [self.delegate placeBookmarkSelected:place];
    [self dismissModalViewControllerAnimated:TRUE];
}

- (void)didSelectContactRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    
}

- (void)didSelectCurrentLocationRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    OBAPlace * place = [OBAPlace placeWithCurrentLocation];
    [self.delegate placeBookmarkSelected:place];
    [self dismissModalViewControllerAnimated:TRUE];
}


- (void) refreshData {
	
    OBACurrentTravelModeController * controller = _appContext.currentTravelModeController;
    _currentLocations = [NSObject releaseOld:_currentLocations retainNew:controller.currentModes];
    
	OBAModelDAO * dao = _appContext.modelDao;
	_bookmarks = [NSObject releaseOld:_bookmarks retainNew:dao.bookmarks];
	_recents = [NSObject releaseOld:_recents retainNew:dao.recentPlaces];
    
	_bookmarkEditButton.enabled = [_bookmarks count] > 0;
    _recentClearButton.enabled = [_recents count] > 0;
}
		
- (void) abortEditing {
	self.editing = FALSE;
	[self.tableView setEditing:FALSE animated:FALSE];

	_bookmarkEditButton.title = @"Edit";
	_bookmarkEditButton.style = UIBarButtonItemStyleBordered;
	
	[self.tableView reloadData];
}

-(IBAction) onCancel:(id)sender {
    [self dismissModalViewControllerAnimated:TRUE];
}

- (IBAction) onEditButton:(id)sender {
	
	BOOL isEditing = ! self.editing;
	[self setEditing:isEditing animated:TRUE];
    
	if( isEditing ) {
		_bookmarkEditButton.title = @"Done";
		_bookmarkEditButton.style = UIBarButtonItemStyleDone;
	}
	else {
		_bookmarkEditButton.title = @"Edit";
		_bookmarkEditButton.style = UIBarButtonItemStyleBordered;
	}
    
    [self.tableView reloadData];
}

-(IBAction) onClearRecentPlaces:(id)sender {
    [_appContext.modelDao clearRecentPlaces];
    [self refreshData];
    [self.tableView reloadData];
}

-(IBAction) onBookmarkTypeChanged:(id)sender {
    UISegmentedControl * segmented = sender;
    NSInteger index = segmented.selectedSegmentIndex;
    switch (index) {
        case 0:
            self.mode = OBABookmarksViewControllerModeBookmarks;
            break;            
        case 1:
            self.mode = OBABookmarksViewControllerModeRecent;
            break;            
        case 2:
            self.mode = OBABookmarksViewControllerModeContacts;
            break;            
        default:
            self.mode = OBABookmarksViewControllerModeBookmarks;
            break;            
    }
}

@end

