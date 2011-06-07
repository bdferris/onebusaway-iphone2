//
//  OBAGeocoderController.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAGeocoderController.h"
#import "OBAPlacesMapViewController.h"



static const NSString * kAddressContext = @"ADDRESS";
static const NSString * kPlaceContext = @"PLACE";


@interface OBAGeocoderController (Private)

- (void) clearPendingRequest;
- (void) submitPlacesRequest;

- (void) processAddresses:(NSArray*)placemarks;
- (void) processPlaces:(OBAPlacemarks*)placemarks;
- (void) notifyDelegateOfPlaces;

- (void) showLocationNotFound:(NSString*)locationName;
- (void) showLocationLookupError:(NSString*)locationName;

@end

@implementation OBAGeocoderController

@synthesize delegate;
@synthesize includeGooglePlaces;

- (id) initWithAppContext:(OBAApplicationContext*)appContext navigationController:(UINavigationController*)navigationController {
    self = [super init];
    if (self) {
        _appContext = [appContext retain];
        _navigationController = [navigationController retain];
        _places = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc {
    [self clearPendingRequest];
    [_appContext release];
    [_navigationController release];
    [_address release];
    [_context release];
    [_places release];
    self.delegate = nil;
    [super dealloc];
}

- (void) geocodeAddress:(NSString*)address withContext:(id)context {
    [self clearPendingRequest];
    _address = [NSObject releaseOld:_address retainNew:address];
    _context = [NSObject releaseOld:_context retainNew:context];
    [_places removeAllObjects];
    _modelRequest = [[_appContext.modelService placemarksForAddress:address withDelegate:self withContext:kAddressContext] retain];
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    
    if (context == kAddressContext) {
        [self processAddresses:obj];
        if( self.includeGooglePlaces ) {
            /**
             * We need to make sure this occurs outside the requestDidFinish: context, since we'll be clearing the previous request
             */
            [self performSelector:@selector(submitPlacesRequest) withObject:nil afterDelay:0.01];
            return;
        }
    }
    else if (context == kPlaceContext) {
        [self processPlaces:obj];
    }
    
    [self notifyDelegateOfPlaces];
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

- (void) submitPlacesRequest {
    [self clearPendingRequest];
    _modelRequest = [[_appContext.modelService placemarksForPlace:_address withDelegate:self withContext:kPlaceContext] retain];

}

- (void) processAddresses:(NSArray*)placemarks {

    for( OBAPlacemark * placemark in placemarks ) {
        OBAPlace * place = [OBAPlace placeWithName:placemark.address coordinate:placemark.coordinate];
        [_places addObject:place];
    }
}

- (void) processPlaces:(OBAPlacemarks*)placemarks {

    for( OBAPlacemark * placemark in placemarks.placemarks ) {
        OBAPlace * place = [[OBAPlace alloc] init];
        place.name = placemark.name;
        place.address = placemark.address;
        place.location = placemark.location;
        [_places addObject:place];
        [place release];
    }
}

- (void) notifyDelegateOfPlaces {
    
    if (! self.delegate)
        return;

    if( [_places count] == 0 ) {
        return;
        [self showLocationNotFound:_address];
        [self.delegate handleGeocoderNoResultFound];
    }
    else if( [_places count] == 1 ) {
        OBAPlace * place = [_places objectAtIndex:0];
        [self.delegate handleGeocoderPlace:place context:_context];
    }
    else {
        
        OBAPlacesMapViewController * vc = [[OBAPlacesMapViewController alloc] initWithPlaces:_places];
        vc.target = self;
        vc.action = @selector(setPlaceFromMap:);
        vc.cancelAction = @selector(cancelPlaceSelection);
        
        UINavigationController * nc =[[UINavigationController alloc] initWithRootViewController:vc];
        [_navigationController presentModalViewController:nc animated:TRUE];
        
        [vc release];
        [nc release];
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
