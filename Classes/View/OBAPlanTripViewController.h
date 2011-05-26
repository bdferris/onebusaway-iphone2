#import "OBAApplicationContext.h"
#import "OBATripController.h"
#import "OBAPlace.h"
#import "OBATargetTime.h"
#import "OBABookmarksViewController.h"
#import "OBAGeocoderController.h"
#import "OBAModalActivityIndicator.h"
#import "Three20UI/Three20UI.h"



typedef enum {
    OBAPlanTripViewControllerContextStartLabel,
    OBAPlanTripViewControllerContextEndLabel
} OBAPlanTripViewControllerContext;


@interface OBAPlanTripViewController : UITableViewController <OBAGeocoderControllerDelegate,OBABookmarksViewControllerDelegate,UITextFieldDelegate> {
    OBAApplicationContext * _appContext;
    OBAPlanTripViewControllerContext _currentContext;
    UITableViewCell * _startAndEndTableViewCell;
    TTPickerTextField * _startTextField;
    TTPickerTextField * _endTextField;
    OBATripQuery * _sourceQuery;
    OBAPlace * _placeFrom;
    OBAPlace * _placeTo;
    OBATripQueryOptimizeForType _optimizeFor;
    OBATargetTime * _targetTime;
    NSArray * _optimizeForLabels;
    NSDateFormatter * _timeFormatter;
    OBAGeocoderController * _geocoder;
    OBAModalActivityIndicator * _activityIndicator;
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext;

- (void) setTripQuery:(OBATripQuery*)query;

-(IBAction) onGoButton:(id)sender;

-(IBAction) onStartTextFieldBookmarkButton:(id)sender;
-(IBAction) onEndTextFieldBookmarkButton:(id)sender;

@end
