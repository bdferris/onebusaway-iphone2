//
//  OBAGeocoderController.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAGeocoderController.h"
#import "OBAPlacesMapViewController.h"



@interface OBAGeocoderController (Private)

- (void) clearPendingRequest;
- (void) showLocationNotFound:(NSString*)locationName;
- (void) showLocationLookupError:(NSString*)locationName;

@end

@implementation OBAGeocoderController

@synthesize delegate;

- (id) initWithAppContext:(OBAApplicationContext*)appContext navigationController:(UINavigationController*)navigationController {
    self = [super init];
    if (self) {
        _appContext = [appContext retain];
        _navigationController = [navigationController retain];
    }
    return self;
}

- (void) dealloc {
    [self clearPendingRequest];
    [_appContext release];
    [_navigationController release];
    [_address release];
    [_context release];
    self.delegate = nil;
    [super dealloc];
}

- (void) geocodeAddress:(NSString*)address withContext:(id)context {
    [self clearPendingRequest];
    _address = [NSObject releaseOld:_address retainNew:address];
    _context = [NSObject releaseOld:_context retainNew:context];
    _modelRequest = [[_appContext.modelService placemarksForAddress:address withDelegate:self withContext:nil] retain];
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    
    NSArray * placemarks = obj;
    
    if( [placemarks count] == 0 ) {
        if (self.delegate) {
            [self showLocationNotFound:_address];
            [self.delegate handleGeocoderNoResultFound];
        }
    }
    else if( [placemarks count] == 1 ) {
        OBAPlacemark * placemark = [placemarks objectAtIndex:0];
        if (self.delegate) {
            OBAPlace * place = [OBAPlace placeWithName:placemark.address coordinate:placemark.coordinate];
            [self.delegate handleGeocoderPlace:place context:_context];
        }
    }
    else {
        
        NSMutableArray * places = [[NSMutableArray alloc] init];
        for( OBAPlacemark * placemark in placemarks ) {
            OBAPlace * place = [OBAPlace placeWithName:placemark.address coordinate:placemark.coordinate];
            [places addObject:place];
        }
        
        OBAPlacesMapViewController * vc = [[OBAPlacesMapViewController alloc] initWithPlaces:places];
        vc.target = self;
        vc.action = @selector(setPlaceFromMap:);
        vc.cancelAction = @selector(cancelPlaceSelection);
        
        UINavigationController * nc =[[UINavigationController alloc] initWithRootViewController:vc];
        [_navigationController presentModalViewController:nc animated:TRUE];

        [vc release];
        [nc release];
        
        [places release];
    }    
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
    if (self.delegate) {
        [self showLocationLookupError:_address];
        [self.delegate handleGeocoderError];
    }
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
    if (self.delegate) {
        [self showLocationLookupError:_address];
        [self.delegate handleGeocoderError];
    }
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    
}

@end


@implementation OBAGeocoderController (Private)


- (void) setPlaceFromMap:(OBAPlace*)place {
    if (self.delegate) {
        [self.delegate handleGeocoderPlace:place context:_context];
    }
}

- (void) cancelPlaceSelection {
    if (self.delegate) {
        [self.delegate handleGeocoderCanceled];
    }
}

- (void) clearPendingRequest {
    if (_modelRequest) {
        [_modelRequest cancel];
        [_modelRequest release];
        _modelRequest = nil;
    }
}


- (void) showLocationNotFound:(NSString*)locationName {
    UIAlertView * view = [[UIAlertView alloc] init];
    view.title = @"Location Not Found";
    view.message = [NSString stringWithFormat:@"We could not find a location for the specified place/address: %@", locationName];
    [view addButtonWithTitle:@"Dismiss"];
    view.cancelButtonIndex = 0;
    [view show];
    [view release];
}

- (void) showLocationLookupError:(NSString*)locationName {
    UIAlertView * view = [[UIAlertView alloc] init];
    view.title = @"Location Lookup Error";
    view.message = [NSString stringWithFormat:@"There was a network/server lookup error for the specified place/address: %@", locationName];
    [view addButtonWithTitle:@"Dismiss"];
    view.cancelButtonIndex = 0;
    [view show];
    [view release];
}

@end
