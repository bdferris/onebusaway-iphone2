//
//  OBAVehicleDepartureTableViewCell.h
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface OBAVehicleDepartureTableViewCell : UITableViewCell {
    
}

@property (nonatomic, retain) IBOutlet UIImageView * modeImage;
@property (nonatomic, retain) IBOutlet UILabel * routeLabel;
@property (nonatomic, retain) IBOutlet UILabel * destinationLabel;
@property (nonatomic, retain) IBOutlet UILabel * statusLabel;
@property (nonatomic, retain) IBOutlet UILabel * timeLabel;
@property (nonatomic, retain) IBOutlet UILabel * minutesLabel;


@end
