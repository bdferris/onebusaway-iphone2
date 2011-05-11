#import "OBAApplicationContext.h"
#import "OBAModalActivityIndicator.h"


@interface OBAReportProblemWithPlannedTripViewController : UITableViewController <OBAModelServiceDelegate> {
    OBAApplicationContext * _appContext;
    NSMutableArray * _problemIds;
	NSMutableArray * _problemNames;
	NSUInteger _problemIndex;
	NSString * _comment;
    
    OBAModalActivityIndicator * _activityIndicatorView;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext;

@end
