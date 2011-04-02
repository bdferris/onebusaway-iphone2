#import "OBAPlanTripViewController.h"
#import "OBAItinerariesV2.h"
#import "OBAPresentation.h"
#import "OBAPlaceDataSource.h"
#import "OBAFixedHeightPickerTextField.h"



static const NSString * kContextPlaceStart = @"kContextPlaceStart";
static const NSString * kContextPlaceEnd = @"kContextPlaceEnd";


@interface OBAPlanTripViewController (Private)

- (BOOL) ensurePlacesAreSet;
- (OBAPlace*) ensurePlaceIsSet:(OBAPlace*)place textField:(TTPickerTextField*)textField;
- (BOOL) ensurePlaceLocationIsSet:(OBAPlace*)place context:(id)context;

- (TTPickerTextField*) getTextFieldForContext:(id)context;
- (OBAPlace*) getPlaceForContext:(id)context;

- (void) showLocationNotFound:(NSString*)locationName;
- (void) showLocationLookupError:(NSString*)locationName;

@end



@implementation OBAPlanTripViewController

@synthesize appContext;
@synthesize placeStart;
@synthesize placeEnd;
@synthesize tripController;

+ (OBAPlanTripViewController*) viewControllerWithApplicationContext:(OBAApplicationContext*)appContext {
    NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBAPlanTripViewController" owner:appContext options:nil];
    OBAPlanTripViewController* vc = [wired objectAtIndex:0];
    vc.appContext = appContext;
    vc.tripController = appContext.tripController;
    return vc;
}

- (void)dealloc
{
    [_startTextField release];
    [_endTextField release];
    
    self.appContext = nil;
    self.placeStart = nil;
    self.placeEnd = nil;
    [super dealloc];
}

- (void) setPlaceFrom:(OBAPlace*)placeFrom placeTo:(OBAPlace*)placeTo {
    if( placeFrom ) {
        if( placeFrom.useCurrentLocation || placeFrom.isBookmark) {
            TTTableItem *item = [TTTableTextItem itemWithText:placeFrom.name URL:nil];
            item.userInfo = placeFrom;
            [_startTextField addCellWithObject:item];
        } else {
            _startTextField.text = placeFrom.name;
        }
    }
    if( placeTo ) {
        if( placeTo.useCurrentLocation || placeTo.isBookmark) {
            TTTableItem *item = [TTTableTextItem itemWithText:placeTo.name URL:nil];
            item.userInfo = placeTo;
            [_endTextField addCellWithObject:item];
        } else {
            _endTextField.text = placeTo.name;
        }
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

    _startTextField = [[OBAFixedHeightPickerTextField alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(self.view.bounds) - 20, 40)];
    _startTextField.dataSource = [[[OBAPlaceDataSource alloc] initWithAppContext:self.appContext] autorelease];;
    _startTextField.searchesAutomatically = TRUE;
    _startTextField.borderStyle = UITextBorderStyleRoundedRect;
    _startTextField.leftView = startLabel;
    _startTextField.leftViewMode = UITextFieldViewModeAlways;
    _startTextField.rightView = startBookmarkButton;
    _startTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    _startTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _startTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _startTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    _endTextField = [[OBAFixedHeightPickerTextField alloc] initWithFrame:CGRectMake(10, 60, CGRectGetWidth(self.view.bounds) - 20, 40)];
    _endTextField.dataSource = [[[OBAPlaceDataSource alloc] initWithAppContext:self.appContext] autorelease];;
    _endTextField.searchesAutomatically = TRUE;
    _endTextField.borderStyle = UITextBorderStyleRoundedRect;
    _endTextField.leftView = endLabel;
    _endTextField.leftViewMode = UITextFieldViewModeAlways;
    _endTextField.rightView = endBookmarkButton;
    _endTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
    _endTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _endTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _endTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

    [self.view addSubview:_startTextField];
    [self.view addSubview:_endTextField];
    
    [endLabel release];
    [startLabel release];
    
    self.hidesBottomBarWhenPushed = TRUE;  
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
    OBABookmarksViewController * vc = [[OBABookmarksViewController alloc] initWithApplicationContext:self.appContext];
    vc.delegate = self;
    vc.includeCurrentLocation = TRUE;
    _currentContext = OBAPlanTripViewControllerContextStartLabel;
    [self.navigationController pushViewController:vc animated:TRUE];
    [vc release];
}

-(IBAction) onEndTextFieldBookmarkButton:(id)sender {
    OBABookmarksViewController * vc = [[OBABookmarksViewController alloc] initWithApplicationContext:self.appContext];
    vc.delegate = self;
    vc.includeCurrentLocation = TRUE;
    _currentContext = OBAPlanTripViewControllerContextEndLabel;
    [self.navigationController pushViewController:vc animated:TRUE];
    [vc release];
}
     
#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    
    if( context == kContextPlaceStart || context == kContextPlaceEnd ) {

        NSArray * placemarks = obj;
        
        if( [placemarks count] == 0 ) {
            TTPickerTextField * textField = [self getTextFieldForContext:context];
            [self showLocationNotFound:textField.text];
        }
        else if( [placemarks count] == 1 ) {
            OBAPlacemark * placemark = [placemarks objectAtIndex:0];
            OBAPlace * place = [self getPlaceForContext:context];
            place.location = [[[CLLocation alloc] initWithLatitude:placemark.coordinate.latitude longitude:placemark.coordinate.longitude] autorelease];
            [self ensurePlacesAreSet];
        }
        else {
            
        }    
    }
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
    if( context == kContextPlaceStart || context == kContextPlaceEnd ) {
        TTPickerTextField * textField = [self getTextFieldForContext:context];
        [self showLocationLookupError:textField.text];
    }
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
    if( context == kContextPlaceStart || context == kContextPlaceEnd ) {
        TTPickerTextField * textField = [self getTextFieldForContext:context];
        [self showLocationLookupError:textField.text];
    }
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {

}



#pragma mark OBABookmarksViewControllerDelegate

- (void) placeBookmarkSelected:(OBAPlace*)place {

    TTPickerTextField * field = (_currentContext == OBAPlanTripViewControllerContextStartLabel) ? _startTextField : _endTextField;
    [field removeAllCells];
    
    TTTableItem *item = [TTTableTextItem itemWithText:place.name URL:nil];
    item.userInfo = place;
    [field addCellWithObject:item];
}


@end

@implementation OBAPlanTripViewController (Private)

- (BOOL) ensurePlacesAreSet {

    
    self.placeStart = [self ensurePlaceIsSet:self.placeStart textField:_startTextField];

    if( ! self.placeStart )
        return FALSE;
    
    if( ! [self ensurePlaceLocationIsSet:self.placeStart context:kContextPlaceStart] )
        return FALSE;
        
    self.placeEnd = [self ensurePlaceIsSet:self.placeEnd textField:_endTextField];    
    
    if( ! self.placeEnd )
        return FALSE;
    
    if( ! [self ensurePlaceLocationIsSet:self.placeEnd context:kContextPlaceEnd] )
        return FALSE;
    
    [self.tripController planTripFrom:self.placeStart to:self.placeEnd];
    
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
    
    if( ! place ) {
        NSString * text = textField.text;
        if( [text length] > 0 ) {
            place = [OBAPlace placeWithName:text];
        }
    }
    
    return place;
}

- (BOOL) ensurePlaceLocationIsSet:(OBAPlace*)place context:(id)context {

    if( place.useCurrentLocation ) {                
        OBALocationManager * locationManager = self.appContext.locationManager;
        place.location = locationManager.currentLocation;
        return TRUE;
    }
    
    if (! place.location) {
        OBAModelService * modelService = self.appContext.modelService;
        [modelService placemarksForAddress:place.name withDelegate:self withContext:context];
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
        return self.placeStart;
    }
    else if( context == kContextPlaceEnd ) {
        return self.placeEnd;
    }
    return nil;
}

- (void) showLocationNotFound:(NSString*)locationName {
    UIAlertView * view = [[UIAlertView alloc] init];
    view.title = @"Location Not Found";
    view.message = [NSString stringWithFormat:@"We could not find a location for the specified place/address: %@", locationName];
    [view addButtonWithTitle:@"Dismiss"];
    view.cancelButtonIndex = 0;
    [view show];
    [view release];
}

- (void) showLocationLookupError:(NSString*)locationName {
    UIAlertView * view = [[UIAlertView alloc] init];
    view.title = @"Location Lookup Error";
    view.message = [NSString stringWithFormat:@"There was a network/server lookup error for the specified place/address: %@", locationName];
    [view addButtonWithTitle:@"Dismiss"];
    view.cancelButtonIndex = 0;
    [view show];
    [view release];
}

@end
