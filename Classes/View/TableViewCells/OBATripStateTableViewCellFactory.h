#import "OBAApplicationContext.h"
#import "OBATripState.h"
#import "OBATripStateCellIndexPath.h"


@interface OBATripStateTableViewCellFactory : NSObject {
    OBAApplicationContext * _appContext;
    UINavigationController * _navigationController;
    UITableView * _tableView;
    NSDateFormatter * _timeFormatter;
    NSDictionary * _directions;
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext navigationController:(UINavigationController*)navigationController tableView:(UITableView*)tableView;

- (NSInteger) getNumberOfRowsForTripState:(OBATripState*)state;
- (UITableViewCell*) getCellForState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath;
- (void) didSelectRowForState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath;

- (UITableViewCell*) createCellForNoResultsFound;
- (UITableViewCell*) createCellForItinerary:(OBAItineraryV2*)itinerary selected:(BOOL)selected;
- (UITableViewCell*) createCellForStartTrip:(OBATripState*)state includeDetail:(BOOL)includeDetail;
- (UITableViewCell*) createCellForVehicleDeparture:(OBATransitLegV2*)transitLeg itinerary:(OBAItineraryV2*)itinerary includeDetail:(BOOL)includeDetail selected:(BOOL)selected;
- (UITableViewCell*) createCellForVehicleArrival:(OBATransitLegV2*)transitLeg itinerary:(OBAItineraryV2*)itinerary includeDetail:(BOOL)includeDetail selected:(BOOL)selected;

@end
