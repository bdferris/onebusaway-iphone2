#import "OBAApplicationContext.h"
#import "OBATripController.h"
#import "OBAPlace.h"
#import "OBATargetTime.h"
#import "OBABookmarksViewController.h"
#import "Three20UI/Three20UI.h"



typedef enum {
    OBAPlanTripViewControllerContextStartLabel,
    OBAPlanTripViewControllerContextEndLabel
} OBAPlanTripViewControllerContext;


@interface OBAPlanTripViewController : UIViewController <OBAModelServiceDelegate,OBAModelServiceDelegate,OBABookmarksViewControllerDelegate,UITextFieldDelegate> {
    OBAPlanTripViewControllerContext _currentContext;
    TTPickerTextField * _startTextField;
    TTPickerTextField * _endTextField;
    OBAPlace * _placeFrom;
    OBAPlace * _placeTo;
}

+ (OBAPlanTripViewController*) viewControllerWithApplicationContext:(OBAApplicationContext*)appContext;

@property (nonatomic,retain) IBOutlet OBAApplicationContext * appContext;
@property (nonatomic,retain) OBATripController * tripController;

@property (nonatomic,retain) IBOutlet UISegmentedControl * dateTypePicker;
@property (nonatomic,retain) IBOutlet UIDatePicker * datePicker;

- (void) setTripQuery:(OBATripQuery*)query;

-(IBAction) onGoButton:(id)sender;

-(IBAction) onStartTextFieldBookmarkButton:(id)sender;
-(IBAction) onEndTextFieldBookmarkButton:(id)sender;

-(IBAction) onDateTypeChanged:(id)sender;
-(IBAction) onTimeChanged:(id)sender;

@end
