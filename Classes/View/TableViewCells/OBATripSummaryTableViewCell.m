//
//  OBATripSummaryTableViewCell.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBATripSummaryTableViewCell.h"


@implementation OBATripSummaryTableViewCell

@synthesize modeImage;
@synthesize summaryLabel;
@synthesize timeLabel;
@synthesize minutesLabel;

@synthesize itinerarySelectionButton;
@synthesize selectionTarget;
@synthesize selectionAction;
@synthesize itinerary;

- (void)dealloc
{
    self.modeImage = nil;
    self.summaryLabel = nil;
    self.timeLabel = nil;
    self.minutesLabel = nil;
    
    self.itinerarySelectionButton = nil;
    self.selectionTarget = nil;
    self.itinerary = nil;
    
    [super dealloc];
}

- (IBAction) onItinerarySelectionButton:(id)sender {
    if (self.selectionTarget && self.selectionAction) {
        [self.selectionTarget performSelector:self.selectionAction withObject:self];
    }
}

@end
