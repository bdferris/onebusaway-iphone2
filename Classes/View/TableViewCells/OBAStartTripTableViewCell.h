#import "OBATripStateTableViewCells.h"


@interface OBAStartTripTableViewCell : UITableViewCell <OBAHasTimeLabels> {
    
}

@property (nonatomic,retain) IBOutlet UILabel * statusLabel;
@property (nonatomic,retain) IBOutlet UILabel * timeLabel;
@property (nonatomic,retain) IBOutlet UILabel * minutesLabel;

@end
