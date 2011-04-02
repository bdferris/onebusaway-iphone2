#import "OBAVehicleRideTableViewCell.h"


@implementation OBAVehicleRideTableViewCell

@synthesize modeImage;
@synthesize routeLabel;
@synthesize destinationLabel;
@synthesize statusLabel;

- (void) dealloc
{
    self.modeImage = nil;
    self.routeLabel = nil;
    self.destinationLabel = nil;
    self.statusLabel = nil;
    [super dealloc];    
}
@end
