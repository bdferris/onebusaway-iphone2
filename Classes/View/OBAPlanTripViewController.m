#import "OBAPlanTripViewController.h"



@interface OBAPlanTripViewController (Private)

- (void) showLocationNotFound:(NSString*)locationName;

@end

@implementation OBAPlanTripViewController

@synthesize appContext;
@synthesize startTextField;
@synthesize endTextField;
@synthesize searchResults;

+ (OBAPlanTripViewController*) viewControllerWithApplicationContext:(OBAApplicationContext*)appContext {
    NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBAPlanTripViewController" owner:nil options:nil];
    OBAPlanTripViewController* vc = [wired objectAtIndex:0];
    vc.appContext = appContext;
    return vc;
}

- (void)dealloc
{
    [_placeStart release];
    [_placeEnd release];
    
    self.appContext = nil;
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
    
    UIButton * bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage * bookmarkImage = [UIImage imageNamed:@"BookmarkButton.png"];
    [bookmarkButton setFrame:CGRectMake(0, 0, bookmarkImage.size.width, bookmarkImage.size.height)];
    [bookmarkButton setImage:bookmarkImage forState:UIControlStateNormal];
    
    UITextField * startTF = self.startTextField;
    UITextField * endTF = self.endTextField;
    
    startTF.leftView = startLabel;
    startTF.leftViewMode = UITextFieldViewModeAlways;
    
    endTF.leftView = endLabel;
    endTF.leftViewMode = UITextFieldViewModeAlways;
    endTF.rightView = bookmarkButton;
    endTF.rightViewMode = UITextFieldViewModeUnlessEditing;
    
    [endLabel release];
    [startLabel release];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction) onGoButton:(id)sender {
    OBAApplicationContext * context = self.appContext;
    OBAModelService * modelService = context.modelService;
    
    UITextField * endTF = self.endTextField;
    [modelService placemarksForAddress:endTF.text withDelegate:self withContext:nil];
}
     
#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    
    NSArray * placemarks = obj;

    if( [placemarks count] == 0 ) {
        [self showLocationNotFound:@""];
    }
    else if( [placemarks count] == 1 ) {
        
    }
    else {
        
    }    
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
    NSLog(@"No!");
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
    NSLog(@"No!");
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    NSLog(@"No!");
}

@end

@implementation OBAPlanTripViewController (Private)

- (void) showLocationNotFound:(NSString*)locationName {
    UIAlertView * view = [[UIAlertView alloc] init];
    view.title = @"Location Not Found";
    view.message = [NSString stringWithFormat:@"We could not find a location for the specified place/address: %@", locationName];
    [view addButtonWithTitle:@"Dismiss"];
    view.cancelButtonIndex = 0;
    [view show];
    [view release];
}

@end
