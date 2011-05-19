//
//  OBAPickTimeViewController.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 5/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAPickTimeViewController.h"


@implementation OBAPickTimeViewController

@synthesize dateTypePicker;
@synthesize datePicker;

@synthesize target;
@synthesize action;

+ (OBAPickTimeViewController*) viewController {
    NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBAPickTimeViewController" owner:nil options:nil];
    OBAPickTimeViewController * vc = [wired objectAtIndex:0];
    return vc;
}

- (id)init
{
    self = [super initWithNibName:@"OBAPickTimeViewController" bundle:nil];
    if (self) {

    }
    return self;
}

- (void)dealloc
{
    self.dateTypePicker = nil;
    self.datePicker = nil;
    self.target = nil;
    
    [super dealloc];
}

-(IBAction) onDateTypeChanged:(id)sender {
    
    UISegmentedControl * dateTypePickerControl = self.dateTypePicker;
    UIDatePicker * datePickerControl = self.datePicker;
    
    NSInteger index = [dateTypePickerControl selectedSegmentIndex];
    
    switch (index) {
        case 1:
        case 2:
            datePickerControl.enabled = TRUE;
            break;
        default:
            datePickerControl.enabled = FALSE;
            break;
    }
}

- (IBAction) onDoneButton:(id)sender {
    if( self.target && self.action ) {
        [self.target performSelector:self.action withObject:self.targetTime];
    }
    [self.navigationController popViewControllerAnimated:TRUE];
}

- (OBATargetTime*) targetTime {
    
    UISegmentedControl * dateTypePickerControl = self.dateTypePicker;
    NSInteger index = [dateTypePickerControl selectedSegmentIndex];
    
    UIDatePicker * datePickerControl = self.datePicker;
    NSDate * time = [datePickerControl date];    
    
    switch (index) {
        case 1:
            return [OBATargetTime timeDepartBy:time];
        case 2:
            return [OBATargetTime timeArriveBy:time];
        default:
            return [OBATargetTime timeNow];
    }
}

- (void) setTargetTime:(OBATargetTime *)targetTime {
    UISegmentedControl * dateTypePickerControl = self.dateTypePicker;
    UIDatePicker * datePickerControl = self.datePicker;
    switch (targetTime.type) {
        case OBATargetTimeTypeNow:
            dateTypePickerControl.selectedSegmentIndex = 0;
            datePickerControl.date = [NSDate date];
            break;
        case OBATargetTimeTypeDepartBy:
            dateTypePickerControl.selectedSegmentIndex = 1;
            datePickerControl.date = targetTime.time;
            break;
        case OBATargetTimeTypeArriveBy:
            dateTypePickerControl.selectedSegmentIndex = 2;
            datePickerControl.date = targetTime.time;
            break;                
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.dateTypePicker.selectedSegmentIndex = 0;    
    self.datePicker.enabled = FALSE;
    self.datePicker.date = [NSDate date];
}

@end
