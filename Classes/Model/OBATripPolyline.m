//
//  OBATripPolyline.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 3/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBATripPolyline.h"


@implementation OBATripPolyline

@synthesize polyline;
@synthesize polylineType;

+ (OBATripPolyline*) tripPolyline:(MKPolyline*)polyline type:(OBATripPolylineType)type {
    OBATripPolyline* tripPolyline = [[[OBATripPolyline alloc] init] autorelease];
    tripPolyline.polyline = polyline;
    tripPolyline.polylineType = type;
    return tripPolyline;
}

- (void) dealloc {
    self.polyline = nil;
    [super dealloc];
}

- (MKMapRect) boundingMapRect {
    return self.polyline.boundingMapRect;
}

- (CLLocationCoordinate2D) coordinate {
    return self.polyline.coordinate;
}

- (BOOL)intersectsMapRect:(MKMapRect)mapRect {
    return [self.polyline intersectsMapRect:mapRect];
}

@end
