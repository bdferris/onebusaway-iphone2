#import "OBAPlanTripViewController.h"
#import "OBAItinerariesV2.h"
#import "OBAPresentation.h"


static const NSString * kContextPlaceStart = @"kContextPlaceStart";
static const NSString * kContextPlaceEnd = @"kContextPlaceEnd";
static const NSString * kContextPlanTrip = @"kContextPlanTrip";


@interface OBAPlanTripViewController (Private)

- (BOOL) ensurePlacesAreSet;
- (UITextField*) getTextFieldForContext:(id)context;
- (void) setPlace:(OBAPlace*)place forContext:(id)context;
- (void) showLocationNotFound:(NSString*)locationName;
- (void) showLocationLookupError:(NSString*)locationName;

@end

@implementation OBAPlanTripViewController

@synthesize appContext;
@synthesize placeStart;
@synthesize placeEnd;
@synthesize tripController;
@synthesize startTextField;
@synthesize endTextField;
@synthesize searchResults;

+ (OBAPlanTripViewController*) viewControllerWithApplicationContext:(OBAApplicationContext*)appContext {
    NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBAPlanTripViewController" owner:nil options:nil];
    OBAPlanTripViewController* vc = [wired objectAtIndex:0];
    vc.appContext = appContext;
    vc.tripController = appContext.tripController;
    return vc;
}

- (void)dealloc
{
    self.appContext = nil;
    self.placeStart = nil;
    self.placeEnd = nil;
    self.startTextField = nil;
    self.endTextField = nil;
    self.searchResults = nil;
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    
    UILabel * startLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 12)];
    startLabel.text = @"Start:";
    startLabel.textColor = [UIColor grayColor];
    startLabel.textAlignment = UITextAlignmentRight;
    
    UILabel * endLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 12)];
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

    
    UITextField * startTF = self.startTextField;
    UITextField * endTF = self.endTextField;
    
    startTF.leftView = startLabel;
    startTF.leftViewMode = UITextFieldViewModeAlways;
    startTF.rightView = startBookmarkButton;
    startTF.rightViewMode = UITextFieldViewModeUnlessEditing;
    
    endTF.leftView = endLabel;
    endTF.leftViewMode = UITextFieldViewModeAlways;
    endTF.rightView = endBookmarkButton;
    endTF.rightViewMode = UITextFieldViewModeUnlessEditing;
    
    [endLabel release];
    [startLabel release];
    
    self.placeStart = nil;
    self.placeEnd = nil;
    
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
    _currentContext = OBAPlanTripViewControllerContextStartLabel;
    [self.navigationController pushViewController:vc animated:TRUE];
    [vc release];
}

-(IBAction) onEndTextFieldBookmarkButton:(id)sender {
    OBABookmarksViewController * vc = [[OBABookmarksViewController alloc] initWithApplicationContext:self.appContext];
    vc.delegate = self;
    _currentContext = OBAPlanTripViewControllerContextEndLabel;
    [self.navigationController pushViewController:vc animated:TRUE];
    [vc release];
}
     
#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    
    if( context == kContextPlaceStart || context == kContextPlaceEnd ) {

        NSArray * placemarks = obj;
        
        if( [placemarks count] == 0 ) {
            UITextField * textField = [self getTextFieldForContext:context];
            [self showLocationNotFound:textField.text];
        }
        else if( [placemarks count] == 1 ) {
            OBAPlacemark * placemark = [placemarks objectAtIndex:0];
            OBAPlace * place = [[OBAPlace alloc] initWithName:placemark.address coordinate:placemark.coordinate];
            [self setPlace:place forContext:context];
            [place release];
            [self ensurePlacesAreSet];
        }
        else {
            
        }    
    }
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
    if( context == kContextPlaceStart || context == kContextPlaceEnd ) {
        UITextField * textField = [self getTextFieldForContext:context];
        [self showLocationLookupError:textField.text];
    }
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
    if( context == kContextPlaceStart || context == kContextPlaceEnd ) {
        UITextField * textField = [self getTextFieldForContext:context];
        [self showLocationLookupError:textField.text];
    }
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {

}



#pragma mark OBABookmarksViewControllerDelegate

- (void) currentLocationBookmarkSelected {
    OBAPickerTextField * field = (_currentContext == OBAPlanTripViewControllerContextStartLabel) ? self.startTextField : self.endTextField;
    field.text = @"Current Location";
    field.fixed = TRUE;
}


@end

@implementation OBAPlanTripViewController (Private)

- (BOOL) ensurePlacesAreSet {

    OBAApplicationContext * context = self.appContext;
    OBAModelService * modelService = context.modelService;
    
    if( ! self.placeStart ) {
        UITextField * startTF = self.startTextField;
        [modelService placemarksForAddress:startTF.text withDelegate:self withContext:kContextPlaceStart];
        return FALSE;
    }

    if( ! self.placeEnd ) {
        UITextField * endTF = self.endTextField;
        [modelService placemarksForAddress:endTF.text withDelegate:self withContext:kContextPlaceEnd];
        return FALSE;
    }
    
    [self.tripController planTripFrom:self.placeStart to:self.placeEnd];
    
    return TRUE;
}

- (UITextField*) getTextFieldForContext:(id)context {
    if( context == kContextPlaceStart ) {
        return self.startTextField;
    }
    else if( context == kContextPlaceEnd ) {
        return self.endTextField;
    }
    return nil;
}

- (void) setPlace:(OBAPlace*)place forContext:(id)context {
    if( context == kContextPlaceStart ) {
        self.placeStart = place;
    }
    else if( context == kContextPlaceEnd ) {
        self.placeEnd = place;
    }
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
