#import "OBAApplicationContext.h"
#import "OBATripState.h"



typedef enum {
    OBATripStateCellTypeTripSummary,
    OBATripStateCellTypeNoResultsFound,
    OBATripStateCellTypeStartTime,
    OBATripStateCellTypeWalkToStop,
    OBATripStateCellTypeWalkToPlace,
    OBATripStateCellTypeDeparture,
    OBATripStateCellTypeRide,
    OBATripStateCellTypeArrival,
    OBATripStateCellTypeNone
} OBATripStateCellType;


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
- (UITableViewCell*) createCellForTripSummary:(OBAItineraryV2*)itinerary;
- (UITableViewCell*) createCellForStartTrip:(OBATripState*)state includeDetail:(BOOL)includeDetail;
- (UITableViewCell*) createCellForVehicleDeparture:(OBATransitLegV2*)transitLeg includeDetail:(BOOL)includeDetail;
- (UITableViewCell*) createCellForVehicleArrival:(OBATransitLegV2*)transitLeg includeDetail:(BOOL)includeDetail;

@end
