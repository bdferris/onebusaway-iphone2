#import "OBAApplicationContext.h"
#import "OBATripController.h"
#import "OBAPlace.h"
#import "OBABookmarksViewController.h"
#import "OBAPickerTextField.h"


typedef enum {
    OBAPlanTripViewControllerContextStartLabel,
    OBAPlanTripViewControllerContextEndLabel
} OBAPlanTripViewControllerContext;


@interface OBAPlanTripViewController : UIViewController <OBAModelServiceDelegate,OBAModelServiceDelegate,OBABookmarksViewControllerDelegate> {
    OBAPlanTripViewControllerContext _currentContext;
}

+ (OBAPlanTripViewController*) viewControllerWithApplicationContext:(OBAApplicationContext*)appContext;

@property (nonatomic,retain) OBAApplicationContext * appContext;
@property (nonatomic,retain) OBATripController * tripController;
@property (nonatomic,retain) OBAPlace * placeStart;
@property (nonatomic,retain) OBAPlace * placeEnd;


@property (nonatomic,retain) IBOutlet OBAPickerTextField * startTextField;
@property (nonatomic,retain) IBOutlet OBAPickerTextField * endTextField;
@property (nonatomic,retain) IBOutlet UITableView * searchResults;

-(IBAction) onGoButton:(id)sender;

-(IBAction) onStartTextFieldBookmarkButton:(id)sender;
-(IBAction) onEndTextFieldBookmarkButton:(id)sender;

@end
