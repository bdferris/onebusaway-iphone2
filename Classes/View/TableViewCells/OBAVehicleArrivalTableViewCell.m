//
//  OBAVehicleArrivalTableViewCell.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAVehicleArrivalTableViewCell.h"


@implementation OBAVehicleArrivalTableViewCell

@synthesize destinationLabel;
@synthesize statusLabel;
@synthesize timeLabel;
@synthesize minutesLabel;

- (void)dealloc
{
    self.destinationLabel = nil;
    self.statusLabel = nil;
    self.timeLabel = nil;
    self.minutesLabel = nil;
    [super dealloc];
}

@end
