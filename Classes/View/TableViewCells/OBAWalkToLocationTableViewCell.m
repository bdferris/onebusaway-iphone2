//
//  OBAWalkToLocationTableViewCell.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAWalkToLocationTableViewCell.h"


@implementation OBAWalkToLocationTableViewCell

@synthesize locationImage;
@synthesize destinationLabel;
@synthesize destinationDetailLabel;

- (void) dealloc {
    self.locationImage = nil;
    self.destinationLabel = nil;
    self.destinationDetailLabel = nil;
    [super dealloc];
}

@end
