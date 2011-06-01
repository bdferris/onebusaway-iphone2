#import "OBAItineraryV2.h"


@protocol OBAHasTimeLabels <NSObject>

@property (nonatomic,retain) IBOutlet UILabel * timeLabel;
@property (nonatomic,retain) IBOutlet UILabel * minutesLabel;

@end


@protocol OBAHasItinerarySelectionButton <NSObject>

@property (nonatomic,retain) IBOutlet UIButton * itinerarySelectionButton;
@property (nonatomic,retain) id selectionTarget;
@property (nonatomic) SEL selectionAction;
@property (nonatomic,retain) OBAItineraryV2 * itinerary;

@end
