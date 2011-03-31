#import "OBAApplicationContext.h"
#import "OBATripController.h"
#import "OBAPlace.h"
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
}

+ (OBAPlanTripViewController*) viewControllerWithApplicationContext:(OBAApplicationContext*)appContext;

@property (nonatomic,retain) OBAApplicationContext * appContext;
@property (nonatomic,retain) OBATripController * tripController;
@property (nonatomic,retain) OBAPlace * placeStart;
@property (nonatomic,retain) OBAPlace * placeEnd;

- (void) setPlaceFrom:(OBAPlace*)placeFrom placeTo:(OBAPlace*)placeTo;

-(IBAction) onGoButton:(id)sender;

-(IBAction) onStartTextFieldBookmarkButton:(id)sender;
-(IBAction) onEndTextFieldBookmarkButton:(id)sender;

@end
