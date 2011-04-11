//
//  OBATripSummaryTableViewCell.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBATripSummaryTableViewCell.h"


@implementation OBATripSummaryTableViewCell

@synthesize summaryLabel;

- (void)dealloc
{
    self.summaryLabel = nil;
    [super dealloc];
}

@end
