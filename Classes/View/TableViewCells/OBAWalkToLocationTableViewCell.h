//
//  OBAWalkToLocationTableViewCell.h
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OBAWalkToLocationTableViewCell : UITableViewCell {
    
}

@property (nonatomic,retain) IBOutlet UIImageView * locationImage;
@property (nonatomic,retain) IBOutlet UILabel * destinationLabel;
@property (nonatomic,retain) IBOutlet UILabel * destinationDetailLabel;

@end
