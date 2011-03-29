#import "OBAApplicationContext.h"
#import "OBAPlace.h"


@interface OBAPlanTripViewController : UIViewController <OBAModelServiceDelegate>{
    OBAPlace * _placeStart;
    OBAPlace * _placeEnd;
}

+ (OBAPlanTripViewController*) viewControllerWithApplicationContext:(OBAApplicationContext*)appContext;

@property (nonatomic,retain) OBAApplicationContext * appContext;
@property (nonatomic,retain) IBOutlet UITextField * startTextField;
@property (nonatomic,retain) IBOutlet UITextField * endTextField;
@property (nonatomic,retain) IBOutlet UITableView * searchResults;

-(IBAction) onGoButton:(id)sender;

@end
