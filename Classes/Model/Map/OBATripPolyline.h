//
//  OBATripPolyline.h
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 3/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

typedef enum {
    OBATripPolylineTypeTransitLeg,
    OBATripPolylineTypeStreetLeg
} OBATripPolylineType;


@interface OBATripPolyline : NSObject <MKOverlay> {
    
}

+ (OBATripPolyline*) tripPolyline:(MKPolyline*)polyline type:(OBATripPolylineType)type;

@property (nonatomic,retain) MKPolyline * polyline;
@property (nonatomic) OBATripPolylineType polylineType;

@end
