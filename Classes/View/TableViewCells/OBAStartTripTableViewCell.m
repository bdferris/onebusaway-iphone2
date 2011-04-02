//
//  OBAStartTripTableViewCell.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAStartTripTableViewCell.h"


@implementation OBAStartTripTableViewCell

@synthesize statusLabel;
@synthesize timeLabel;
@synthesize minutesLabel;

- (void) dealloc {
    self.statusLabel = nil;
    self.timeLabel = nil;
    self.minutesLabel = nil;
    [super dealloc];
}
@end
