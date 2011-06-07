#import "OBAPlanTripViewController.h"
#import "OBAPlacesMapViewController.h"
#import "OBAItinerariesV2.h"
#import "OBAPresentation.h"
#import "OBAPlaceDataSource.h"
#import "OBAFixedHeightPickerTextField.h"
#import "OBAListSelectionViewController.h"
#import "OBAPickTimeViewController.h"
#import "OBAPlacePresentation.h"


static const NSString * kContextPlaceStart = @"kContextPlaceStart";
static const NSString * kContextPlaceEnd = @"kContextPlaceEnd";

typedef enum {
    OBASectionTypeNone,
    OBASectionTypeStartAndEnd,
    OBASectionTypeOptions,
    OBASectionTypePlanTrip
} OBASectionType;


@interface OBAPlanTripViewController (Private)

- (OBASectionType) getSectionTypeForSectionIndex:(NSInteger)sectionIndex;
- (NSInteger) getSectionIndexForSectionType:(OBASectionType)sectionType;

- (UITableViewCell *) optionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (void) didSelectOptionsRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

- (void) refreshFromSourceQuery;

- (BOOL) ensurePlacesAreSet;
- (OBAPlace*) ensurePlaceIsSet:(OBAPlace*)place textField:(TTPickerTextField*)textField;
- (BOOL) ensurePlaceLocationIsSet:(OBAPlace*)place context:(id)context;

- (TTPickerTextField*) getTextFieldForContext:(id)context;
- (OBAPlace*) getPlaceForContext:(id)context;

@end



@implementation OBAPlanTripViewController

- (id) initWithAppContext:(OBAApplicationContext*)appContext {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _appContext = [appContext retain];
        _optimizeFor = [appContext.modelDao defaultTripQueryOptimizeForType];
        _targetTime = [[OBATargetTime timeNow] retain];  

        self.navigationItem.title = @"Plan Your Trip";
        self.navigationItem.backBarButtonItem.title = @"Cancel";
        self.hidesBottomBarWhenPushed = TRUE;
    }
    return self;
}

- (void)dealloc
{
    [_appContext release];
    
    [_startAndEndTableViewCell release];
    [_startTextField release];
    [_endTextField release];
    
    [_sourceQuery release];
    [_placeFrom release];
    [_placeTo release];
    
    [_targetTime release];
    [_optimizeForLabels release];
    [_timeFormatter release];
    
    [_geocoder release];
    [_activityIndicator release];
    
    [super dealloc];
}

- (void) setTripQuery:(OBATripQuery*)query {
    
    OBALogDebug(@"Set trip query");
    
    _sourceQuery = [NSObject releaseOld:_sourceQuery retainNew:query];
    [self refreshFromSourceQuery];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    OBALogDebug(@"View did load...");
    
    _startAndEndTableViewCell = [[UITableViewCell getOrCreateCellForTableView:self.tableView cellId:@"StartAndEnd"] retain];
    _startAndEndTableViewCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    _startAndEndTableViewCell.accessoryType = UITableViewCellAccessoryNone;
    
    UILabel * startLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 20)];
    startLabel.text = @"Start:";
    startLabel.textColor = [UIColor grayColor];
    startLabel.textAlignment = UITextAlignmentRight;
    
    UILabel * endLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 20)];
    endLabel.text = @"End:";
    endLabel.textColor = [UIColor grayColor];
    endLabel.textAlignment = UITextAlignmentRight;
    
    UIImage * bookmarkImage = [UIImage imageNamed:@"BookmarkButton.png"];
    
    UIButton * startBookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [startBookmarkButton setFrame:CGRectMake(0, 0, bookmarkImage.size.width, bookmarkImage.size.height)];
    [startBookmarkButton setImage:bookmarkImage forState:UIControlStateNormal];
    [startBookmarkButton addTarget:self action:@selector(onStartTextFieldBookmarkButton:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton * endBookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [endBookmarkButton setFrame:CGRectMake(0, 0, bookmarkImage.size.width, bookmarkImage.size.height)];
    [endBookmarkButton setImage:bookmarkImage forState:UIControlStateNormal];
    [endBookmarkButton addTarget:self action:@selector(onEndTextFieldBookmarkButton:) forControlEvents:UIControlEventTouchUpInside];

    static const int kCellMargin = 18;
    
    _startTextField = [[OBAFixedHeightPickerTextField alloc] initWithFrame:CGRectMake(kCellMargin, 10, CGRectGetWidth(self.view.bounds) - 2 * kCellMargin, 40)];
    _startTextField.dataSource = [[[OBAPlaceDataSource alloc] initWithAppContext:_appContext] autorelease];;
    _startTextField.searchesAutomatically = TRUE;
    _startTextField.borderStyle = UITextBorderStyleRoundedRect;
    _startTextField.leftView = startLabel;
    _startTextField.leftViewMode = UITextFieldViewModeAlways;
    _startTextField.rightView = startBookmarkButton;
    _startTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    _startTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _startTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _startTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _startTextField.delegate = self;
    
    _endTextField = [[OBAFixedHeightPickerTextField alloc] initWithFrame:CGRectMake(kCellMargin, 60, CGRectGetWidth(self.view.bounds) - 2 * kCellMargin, 40)];
    _endTextField.dataSource = [[[OBAPlaceDataSource alloc] initWithAppContext:_appContext] autorelease];;
    _endTextField.searchesAutomatically = TRUE;
    _endTextField.borderStyle = UITextBorderStyleRoundedRect;
    _endTextField.leftView = endLabel;
    _endTextField.leftViewMode = UITextFieldViewModeAlways;
    _endTextField.rightView = endBookmarkButton;
    _endTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    _endTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _endTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _endTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _endTextField.delegate = self;
    
    [_startAndEndTableViewCell addSubview:_startTextField];
    [_startAndEndTableViewCell addSubview:_endTextField];
    
    [endLabel release];
    [startLabel release];
    
    /**
     * We default to showing the current location in the start field
     */ 
    OBAPlace * place = [OBAPlace placeWithCurrentLocation];
    TTTableItem *item = [OBAPlacePresentation getPlaceAsItem:place];
    [_startTextField removeAllCells];
    [_startTextField addCellWithObject:item];
    
    _optimizeForLabels = [[NSArray alloc] initWithObjects:@"Prefer best route", @"Prefer fastest route", @"Prefer fewer transfers", @"Prefer less walking", nil];
    
    _timeFormatter = [[NSDateFormatter alloc] init];
    [_timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    _geocoder = [[OBAGeocoderController alloc] initWithAppContext:_appContext navigationController:self.navigationController];
    _geocoder.delegate = self;
    _geocoder.includeGooglePlaces = TRUE;
    
    _activityIndicator = [[OBAModalActivityIndicator alloc] init];                          
    
    [self refreshFromSourceQuery];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction) onGoButton:(id)sender {
    [self ensurePlacesAreSet];
}

-(IBAction) onStartTextFieldBookmarkButton:(id)sender {
    _currentContext = OBAPlanTripViewControllerContextStartLabel;
    [OBABookmarksViewController showBookmarksViewControllerWithAppContext:_appContext parent:self.navigationController delegate:self includeCurrentLocation:TRUE];
}

-(IBAction) onEndTextFieldBookmarkButton:(id)sender {
    _currentContext = OBAPlanTripViewControllerContextEndLabel;
    [OBABookmarksViewController showBookmarksViewControllerWithAppContext:_appContext parent:self.navigationController delegate:self includeCurrentLocation:TRUE];
}

- (IBAction) onOptimizeForChagned:(id)sender {
    
    NSIndexPath * path = sender;
    _optimizeFor = path.row;

    NSIndexSet * sections = [NSIndexSet indexSetWithIndex:[self getSectionIndexForSectionType:OBASectionTypeOptions]];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction) onTargetTimeChanged:(id)sender {
    _targetTime = [NSObject releaseOld:_targetTime retainNew:sender];
    NSIndexSet * sections = [NSIndexSet indexSetWithIndex:[self getSectionIndexForSectionType:OBASectionTypeOptions]];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OBASectionType sectionType = [self getSectionTypeForSectionIndex:section];

    switch (sectionType) {
        case OBASectionTypeStartAndEnd:
        case OBASectionTypePlanTrip:
            return 1;
        case OBASectionTypeOptions:
            return 2;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OBASectionType sectionType = [self getSectionTypeForSectionIndex:indexPath.section];
    
    switch (sectionType) {
        case OBASectionTypeStartAndEnd:
            return _startAndEndTableViewCell;
        case OBASectionTypeOptions:
            return [self optionsCellForRowAtIndexPath:indexPath tableView:tableView];
        case OBASectionTypePlanTrip: {
            UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"Plan Trip"];
            cell.textLabel.text = @"Plan Trip";
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1.0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            return cell;
        }
            
        default:
            return nil;
    }
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    OBASectionType sectionType = [self getSectionTypeForSectionIndex:indexPath.section];
    if (sectionType == OBASectionTypeStartAndEnd )
        return 110;
    return 44;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    OBASectionType sectionType = [self getSectionTypeForSectionIndex:section];
    if( sectionType == OBASectionTypeOptions )
        return @"Options:";
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OBASectionType sectionType = [self getSectionTypeForSectionIndex:indexPath.section];

    switch (sectionType) {
    
        case OBASectionTypeOptions: {
            [self didSelectOptionsRowAtIndexPath:indexPath tableView:tableView];
            break;
        }
            
        case OBASectionTypePlanTrip:
            [self ensurePlacesAreSet];
            break;
            
        default:
            break;
    }
}

#pragma mark OBAGeocoderControllerDelegate

-(void) handleGeocoderPlace:(OBAPlace*)place context:(id)context {
    [_activityIndicator hide];
    OBAPlace * currentPlace = [self getPlaceForContext:context];
    currentPlace.location = place.location;
    [self ensurePlacesAreSet];
}

-(void) handleGeocoderError {
    [_activityIndicator hide];
}

-(void) handleGeocoderNoResultFound {
    [_activityIndicator hide];
}

-(void) handleGeocoderCanceled {
    [_activityIndicator hide];
}

#pragma mark OBABookmarksViewControllerDelegate

- (void) placeBookmarkSelected:(OBAPlace*)place {

    TTPickerTextField * field = (_currentContext == OBAPlanTripViewControllerContextStartLabel) ? _startTextField : _endTextField;
    [field removeAllCells];
    
    TTTableItem *item = [OBAPlacePresentation getPlaceAsItem:place];
    [field addCellWithObject:item];
}

#pragma mark UITextFieldDelegate

- (void) textField:(UITextField*)field didAddCellAtIndex:(NSInteger)index {
    [field resignFirstResponder];
}

@end



@implementation OBAPlanTripViewController (Private)

- (OBASectionType) getSectionTypeForSectionIndex:(NSInteger)sectionIndex {
    
    switch (sectionIndex) {
        case 0:
            return OBASectionTypeStartAndEnd;
        case 1:
            return OBASectionTypePlanTrip;            
        case 2:
            return OBASectionTypeOptions;
        default:
            return OBASectionTypeNone;
    }
}
                             
- (NSInteger) getSectionIndexForSectionType:(OBASectionType)sectionType {
    switch (sectionType) {
        case OBASectionTypeStartAndEnd:
            return 0;
        case OBASectionTypePlanTrip:
            return 1;
        case OBASectionTypeOptions:
            return 2;
        default:
            return -1;
    }
}

- (UITableViewCell *) optionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    
    if( indexPath.row == 0 ) {
        
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        
        NSString * t = [_timeFormatter stringFromDate:_targetTime.time];
        
        switch(_targetTime.type) {
            case OBATargetTimeTypeNow:
                cell.textLabel.text = @"Depart Now";
                break;
            case OBATargetTimeTypeDepartBy:
                cell.textLabel.text = [NSString stringWithFormat:@"Depart at %@",t];
                break;
            case OBATargetTimeTypeArriveBy:
                cell.textLabel.text = [NSString stringWithFormat:@"Arrive by %@",t];
                break;
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    
    if( indexPath.row == 1 ) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
        switch (_optimizeFor) {
            case OBATripQueryOptimizeForTypeDefault:
                cell.textLabel.text = @"Prefer best route";
                break;
            case OBATripQueryOptimizeForTypeMinimizeTime:
                cell.textLabel.text = @"Prefer fastest route";
                break;
            case OBATripQueryOptimizeForTypeMinimizeTransfers:
                cell.textLabel.text = @"Prefer fewer transfers";
                break;
            case OBATripQueryOptimizeForTypeMinimizeWalking:
                cell.textLabel.text = @"Prefer less walking";
                break;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    
    return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (void) didSelectOptionsRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    
    if( indexPath.row == 0 ) {
        OBAPickTimeViewController * vc = [OBAPickTimeViewController viewController];
        vc.targetTime = _targetTime;
        vc.target = self;
        vc.action = @selector(onTargetTimeChanged:);
        [self.navigationController pushViewController:vc animated:TRUE];
    }
    
    if (indexPath.row == 1) {
        NSIndexPath * p = [NSIndexPath indexPathForRow:_optimizeFor inSection:0];
        OBAListSelectionViewController * vc = [[OBAListSelectionViewController alloc] initWithValues:_optimizeForLabels selectedIndex:p];
        vc.exitOnSelection = TRUE;
        vc.target = self;
        vc.action = @selector(onOptimizeForChagned:);
        [self.navigationController pushViewController:vc animated:TRUE];
        [vc release];
    }
}

- (void) refreshFromSourceQuery {
    
    if( ! _sourceQuery )
        return;
    
    OBAPlace * placeFrom = _sourceQuery.placeFrom;
    OBAPlace * placeTo = _sourceQuery.placeTo;
    OBATargetTime * time = _sourceQuery.time;
    
    if( placeFrom ) {        
        if( ! placeFrom.isPlain ) {
            TTTableItem *item = [OBAPlacePresentation getPlaceAsItem:placeFrom];
            [_startTextField removeAllCells];
            [_startTextField addCellWithObject:item];
        } else {
            _startTextField.text = placeFrom.name;
            [_startTextField showSearchResults:FALSE];
        }
    }
    if( placeTo ) {
        if( ! placeTo.isPlain ) {
            TTTableItem *item = [OBAPlacePresentation getPlaceAsItem:placeTo];
            [_endTextField removeAllCells];
            [_endTextField addCellWithObject:item];
        } else {
            _endTextField.text = placeTo.name;
            [_endTextField showSearchResults:FALSE];
        }
    }
    
    if( time ) {
        _targetTime = [NSObject releaseOld:_targetTime retainNew:time];
    }
}

- (BOOL) ensurePlacesAreSet {
    
    _placeFrom = [NSObject releaseOld:_placeFrom retainNew:[self ensurePlaceIsSet:_placeFrom textField:_startTextField]];

    if( ! _placeFrom )
        return FALSE;
    
    if( ! [self ensurePlaceLocationIsSet:_placeFrom context:kContextPlaceStart] )
        return FALSE;
        
    _placeTo = [NSObject releaseOld:_placeTo retainNew:[self ensurePlaceIsSet:_placeTo textField:_endTextField]];
    
    if( ! _placeTo )
        return FALSE;
    
    if( ! [self ensurePlaceLocationIsSet:_placeTo context:kContextPlaceEnd] )
        return FALSE;
    
    [self.navigationController popToRootViewController];    
    
    OBATripQuery * query = [[OBATripQuery alloc] initWithPlaceFrom:_placeFrom placeTo:_placeTo time:_targetTime optimizeFor:_optimizeFor];
    [_appContext.tripController planTripWithQuery:query];
    [query release];
    
    return TRUE;
}

- (OBAPlace*) ensurePlaceIsSet:(OBAPlace*)place textField:(TTPickerTextField*)textField {

    if( ! place ) {
        NSArray * cells = [textField cells];
        if( [cells count] > 0 ) {
            TTTableItem * item = [cells objectAtIndex:0];
            place = item.userInfo;
        }
    }
    
    NSString * text = textField.text;

    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if( [text length] > 0 ) {
        if (! place) {
            place = [OBAPlace placeWithName:text];
        }
        else if ( place.isPlain && ! [text isEqualToString:place.name]) {
            place.name = text;
            place.location = nil;
        }
    }
    
    return place;
}

- (BOOL) ensurePlaceLocationIsSet:(OBAPlace*)place context:(id)context {

    if( place.isCurrentLocation ) {                
        OBALocationManager * locationManager = _appContext.locationManager;
        place.location = locationManager.currentLocation;
        return TRUE;
    }
    
    if (! place.location) {
        NSString * toGeocode = place.name;
        if (place.address)
            toGeocode = place.address;
        [_geocoder geocodeAddress:toGeocode withContext:context];
        [_activityIndicator show:self.view];
        return FALSE;
    }
    
    return TRUE;
}

- (TTPickerTextField*) getTextFieldForContext:(id)context {
    if( context == kContextPlaceStart ) {
        return _startTextField;
    }
    else if( context == kContextPlaceEnd ) {
        return _endTextField;
    }
    return nil;
}

- (OBAPlace*) getPlaceForContext:(id)context {
    if( context == kContextPlaceStart ) {
        return _placeFrom;
    }
    else if( context == kContextPlaceEnd ) {
        return _placeTo;
    }
    return nil;
}

- (void) setFromPlaceFromPlacemark:(OBAPlace*)place {
    
    place = [OBAPlace placeWithBookmarkName:place.name location:place.location];
    _placeFrom = [NSObject releaseOld:_placeFrom retainNew:place];
    
    [_startTextField removeAllCells];
    _startTextField.text = @"";
    
    TTTableItem *item = [OBAPlacePresentation getPlaceAsItem:place];
    [_startTextField addCellWithObject:item];
    
    [self ensurePlacesAreSet];
}

- (void) setToPlaceFromPlacemark:(OBAPlace*)place {
    
    place = [OBAPlace placeWithBookmarkName:place.name location:place.location];
    _placeTo = [NSObject releaseOld:_placeTo retainNew:place];
    
    [_endTextField removeAllCells];
    _endTextField.text = @"";
    
    TTTableItem *item = [OBAPlacePresentation getPlaceAsItem:place];
    [_endTextField addCellWithObject:item];
    
    [self ensurePlacesAreSet];
}

@end
