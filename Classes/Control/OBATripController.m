#import "OBATripController.h"
#import "OBAItinerariesV2.h"
#import "OBAPresentation.h"
#import "OBATripPolyline.h"
#import "OBASphericalGeometryLibrary.h"


@implementation OBATripController

@synthesize modelService;
@synthesize delegate;

- (void) planTripFrom:(OBAPlace*)fromPlace to:(OBAPlace*)toPlace {

    CLLocation * from = fromPlace.location;
    CLLocation * to = toPlace.location;    
    NSDate * time = [NSDate date];
    
    [self.modelService planTripFrom:from.coordinate to:to.coordinate time:time arriveBy:FALSE options:nil delegate:self context:nil];
}

- (NSArray*) overlays {
    NSMutableArray * list = [NSMutableArray array];
    if( _currentItinerary ) {
        for( OBALegV2 * leg in _currentItinerary.legs ) {
            if( leg.transitLeg ) {
                OBATransitLegV2 * transitLeg = leg.transitLeg;
                if( transitLeg.path ) {
                    MKPolyline * polyline = [OBASphericalGeometryLibrary decodePolylineStringAsMKPolyline:transitLeg.path];
                    OBATripPolyline * tripPolyline = [OBATripPolyline tripPolyline:polyline type:OBATripPolylineTypeTransitLeg];                    
                    [list addObject:tripPolyline];
                }
            }
            if ([leg.streetLegs count] > 0 ) {
                NSMutableArray * allPoints = [NSMutableArray array];
                for( OBAStreetLegV2 * streetLeg in leg.streetLegs ) {
                    if( streetLeg.path ) {
                        NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:streetLeg.path];
                        [allPoints addObjectsFromArray:points];
                    }
                }
                if( [allPoints count] > 0 ) {
                    MKPolyline * polyline = [OBASphericalGeometryLibrary createMKPolylineFromLocations:allPoints];
                    OBATripPolyline * tripPolyline = [OBATripPolyline tripPolyline:polyline type:OBATripPolylineTypeStreetLeg]; 
                    [list addObject:tripPolyline];
                }
            }
        }

    }
    return list;
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {

    OBAEntryWithReferencesV2 * entry = obj;
    OBAItinerariesV2 * itineraries = entry.entry;
    if ([itineraries.itineraries count] > 0 ) {
        _currentItinerary = [[itineraries.itineraries objectAtIndex:0] retain];
        [self.delegate refreshTrip];
    }
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {

}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {

}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    
}

@end
