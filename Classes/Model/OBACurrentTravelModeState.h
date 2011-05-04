//
//  OBACurrentTravelModeState.h
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBATripInstanceRef.h"


@interface OBACurrentTravelModeState : NSObject {
    
}

@property (nonatomic,retain) CLLocation * location;
@property (nonatomic,retain) NSString * blockId;
@property (nonatomic) long long serviceDate;
@property (nonatomic,retain) NSString * vehicleId;
@property (nonatomic,retain) NSString * label;

@end
