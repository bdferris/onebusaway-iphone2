#import "OBATripStateTableViewCells.h"


@interface OBAVehicleDepartureTableViewCell : UITableViewCell <OBAHasItinerarySelectionButton, OBAHasTimeLabels> {
    
}

@property (nonatomic,retain) IBOutlet UIImageView * modeImage;
@property (nonatomic,retain) IBOutlet UILabel * routeLabel;
@property (nonatomic,retain) IBOutlet UILabel * destinationLabel;
@property (nonatomic,retain) IBOutlet UILabel * statusLabel;
@property (nonatomic,retain) IBOutlet UILabel * timeLabel;
@property (nonatomic,retain) IBOutlet UILabel * minutesLabel;

@property (nonatomic,retain) IBOutlet UIButton * itinerarySelectionButton;
@property (nonatomic,retain) id selectionTarget;
@property (nonatomic) SEL selectionAction;
@property (nonatomic,retain) OBAItineraryV2 * itinerary;

- (IBAction) onItinerarySelectionButton:(id)sender;


@end
