#import "OBAApplicationContext.h"
#import "OBAPlacemark.h"


@protocol OBAGeocoderControllerDelegate <NSObject>
-(void) handleGeocoderPlace:(OBAPlace*)place context:(id)context;
-(void) handleGeocoderError;
-(void) handleGeocoderNoResultFound;
-(void) handleGeocoderCanceled;
@end

@interface OBAGeocoderController : NSObject <OBAModelServiceDelegate> {
    OBAApplicationContext * _appContext;
    UINavigationController * _navigationController;
    NSString * _address;
    id _context;
    id<OBAModelServiceRequest> _modelRequest;    
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext navigationController:(UINavigationController*)navigationController;

@property (nonatomic,retain) id<OBAGeocoderControllerDelegate> delegate;

- (void) geocodeAddress:(NSString*)address withContext:(id)context;

@end
