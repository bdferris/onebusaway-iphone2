#import "OBATargetTime.h"


@interface OBAPickTimeViewController : UIViewController {
    
}

+ (OBAPickTimeViewController*) viewController;

@property (nonatomic,retain) IBOutlet UISegmentedControl * dateTypePicker;
@property (nonatomic,retain) IBOutlet UIDatePicker * datePicker;

@property (nonatomic,retain) id target;
@property (nonatomic) SEL action;

@property (nonatomic,assign) OBATargetTime * targetTime;

- (IBAction) onDateTypeChanged:(id)sender;
- (IBAction) onDoneButton:(id)sender;



@end
