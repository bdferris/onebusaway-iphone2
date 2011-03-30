#import "OBAApplicationContext.h"
#import "OBATripController.h"
#import "OBAPlace.h"


@interface OBAPlanTripViewController : UIViewController <OBAModelServiceDelegate,OBAModelServiceDelegate>{

}

+ (OBAPlanTripViewController*) viewControllerWithApplicationContext:(OBAApplicationContext*)appContext;

@property (nonatomic,retain) OBAApplicationContext * appContext;
@property (nonatomic,retain) OBATripController * tripController;
@property (nonatomic,retain) OBAPlace * placeStart;
@property (nonatomic,retain) OBAPlace * placeEnd;


@property (nonatomic,retain) IBOutlet UITextField * startTextField;
@property (nonatomic,retain) IBOutlet UITextField * endTextField;
@property (nonatomic,retain) IBOutlet UITableView * searchResults;

-(IBAction) onGoButton:(id)sender;

@end
