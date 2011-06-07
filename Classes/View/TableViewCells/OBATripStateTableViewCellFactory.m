//
//  OBATripStateTableViewCellFactory.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBATripStateTableViewCellFactory.h"
#import "OBATripStateTableViewCells.h"
#import "OBATripStateCellIndexPath.h"
#import "OBATripSummaryTableViewCell.h"
#import "OBAStartTripTableViewCell.h"
#import "OBAWalkToLocationTableViewCell.h"
#import "OBAVehicleDepartureTableViewCell.h"
#import "OBAVehicleRideTableViewCell.h"
#import "OBAVehicleArrivalTableViewCell.h"
#import "OBAStopIconFactory.h"
#import "OBAPresentation.h"

#import "OBAPlanTripViewController.h"
#import "OBAPickTripViewController.h"
#import "OBAAlarmViewController.h"


typedef struct  {
    long long predictedTime;
    long long scheduledTime;
    NSDate * bestTime;
    NSInteger minutes;
    BOOL isNow;
} OBATimeStruct;


@interface OBATripStateTableViewCellFactory (Private)

- (OBATripStateCellIndexPath*) getCellIndexForTripState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath;

- (UITableViewCell*) createCellForPlanYourTrip;

- (UITableViewCell*) createCellForWalkToStop:(OBAStopV2*)stop;
- (UITableViewCell*) createCellForWalkToPlace:(OBAPlace*)place;
- (UITableViewCell*) createCellForStop:(OBAStopV2*)stop;
- (UITableViewCell*) createCellForVehicleRide:(OBATransitLegV2*)transitLeg;

- (OBATimeStruct) getTimeForItineraryStart:(OBAItineraryV2*)itinerary;
- (OBATimeStruct) getTimeForPredictedTime:(long long)predictedTime scheduledTime:(long long)scheduledTime;

- (void) applyTime:(OBATimeStruct)t toTimeLabels:(id<OBAHasTimeLabels>)cell;
- (NSString*) getMinutesLabelForTime:(OBATimeStruct)t;
- (UIColor*) getMinutesColorForTime:(OBATimeStruct)t;
- (NSString*) getStatusLabelForTransitLeg:(OBATransitLegV2*)transitLeg time:(OBATimeStruct)t;

- (id) getOrCreateCellFromNibNamed:(NSString*)cellId;

@end


@implementation OBATripStateTableViewCellFactory

- (id) initWithAppContext:(OBAApplicationContext*)appContext navigationController:(UINavigationController*)navigationController tableView:(UITableView*)tableView {
    self = [super init];
    if (self) {
        _appContext = [appContext retain];
        _navigationController = [navigationController retain];
        _tableView = [tableView retain];
        
        _timeFormatter = [[NSDateFormatter alloc] init];
		[_timeFormatter setDateStyle:NSDateFormatterNoStyle];
		[_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        NSMutableDictionary * directions = [NSMutableDictionary dictionary];
        [directions setObject:@"North" forKey:@"N"];
        [directions setObject:@"NorthEast" forKey:@"NE"];
        [directions setObject:@"East" forKey:@"E"];
        [directions setObject:@"SouthEast" forKey:@"SE"];
        [directions setObject:@"South" forKey:@"S"];
        [directions setObject:@"SouthWest" forKey:@"SW"];
        [directions setObject:@"West" forKey:@"W"];
        [directions setObject:@"NorthWest" forKey:@"NW"];
        _directions = [directions retain];
    }
    return self;
}

- (void) dealloc {
    [_appContext release];
    [_tableView release];
    [_timeFormatter release];
    [_directions release];
    [super dealloc];
}

- (NSInteger) getNumberOfRowsForTripState:(OBATripState*)state {

    if( state == nil ) {
        return 1;
    }
    
    NSInteger rows = 0;
    
    if( state.noResultsFound )
        rows++;    
    if (state.type == OBATripStateTypeItineraries)
        rows += [state.itineraries count];
    if( state.showStartTime )
        rows++;
    if( state.walkToStop )
        rows++;
    if( state.walkToPlace )
        rows++;
    if (state.stop)
        rows++;
    rows += [state.departures count];
    if( state.ride )
        rows++;
    rows += [state.arrivals count];
    
    return rows;
}

- (UITableViewCell*) getCellForState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath {
    
    if( state == nil ) {
        return [self createCellForPlanYourTrip];
    }

    OBATripStateCellIndexPath * path = [self getCellIndexForTripState:state indexPath:indexPath];

    switch (path.type) {
        case OBATripStateCellTypeItinerary: {
            OBAItineraryV2 * itineray = [state.itineraries objectAtIndex:path.row];
            BOOL selected = state.selectedItineraryIndex == path.row;
            return [self createCellForItinerary:itineray selected:selected];                    
        }
        case OBATripStateCellTypeNoResultsFound:
            return [self createCellForNoResultsFound];
        case OBATripStateCellTypeStartTime:
            return [self createCellForStartTrip:state includeDetail:TRUE];
        case OBATripStateCellTypeWalkToStop:
            return [self createCellForWalkToStop:state.walkToStop];
        case OBATripStateCellTypeWalkToPlace:
            return [self createCellForWalkToPlace:state.walkToPlace];
        case OBATripStateCellTypeStop:
            return [self createCellForStop:state.stop];
        case OBATripStateCellTypeDeparture: {
            OBATransitLegV2 * departure = [state.departures objectAtIndex:path.row];
            OBAItineraryV2 * itinerary = [state.departureItineraries objectAtIndex:path.row];
            BOOL selected = state.selectedDepartureIndex == path.row;
            return [self createCellForVehicleDeparture:departure itinerary:itinerary includeDetail:TRUE selected:selected];
        }
        case OBATripStateCellTypeRide:
            return [self createCellForVehicleRide:state.ride];
        case OBATripStateCellTypeArrival: {
            OBATransitLegV2 * arrival = [state.arrivals objectAtIndex:path.row];
            OBAItineraryV2 * itinerary = [state.arrivalItineraries objectAtIndex:path.row];
            BOOL selected = state.selectedArrivalIndex == path.row;
            return [self createCellForVehicleArrival:arrival itinerary:itinerary includeDetail:TRUE selected:selected];
        }
        default:
            return [UITableViewCell getOrCreateCellForTableView:_tableView];
    }
}

- (void) didSelectRowForState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath {

    if( state == nil) {
        OBAPlanTripViewController * vc = [[OBAPlanTripViewController alloc] initWithAppContext:_appContext];
        [_navigationController pushViewController:vc animated:TRUE];
        [vc release];
        return;
    }
    
    OBATripStateCellIndexPath * path = [self getCellIndexForTripState:state indexPath:indexPath];
    
    switch (path.type) {
        case OBATripStateCellTypeNoResultsFound: {
            OBAPlanTripViewController * vc = [[OBAPlanTripViewController alloc] initWithAppContext:_appContext];
            [vc setTripQuery:_appContext.tripController.query];
            [_navigationController pushViewController:vc animated:TRUE];
            [vc release];
            break;
        }
        case OBATripStateCellTypeItinerary:
        case OBATripStateCellTypeStartTime:
        case OBATripStateCellTypeDeparture:
        case OBATripStateCellTypeArrival:
        {
            OBAAlarmViewController * vc = [[OBAAlarmViewController alloc] initWithAppContext:_appContext tripState:state cellType:path.type];
            [_navigationController pushViewController:vc animated:TRUE];
            [vc release];
        }
        default:
            break;
    }
}

- (UITableViewCell*) createCellForNoResultsFound {
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:_tableView cellId:@"NoResultsFound"];
    cell.textLabel.text = @"No results found";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    return cell;
}

- (UITableViewCell*) createCellForItinerary:(OBAItineraryV2*)itinerary selected:(BOOL)selected {
    
    OBATripSummaryTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBATripSummaryTableViewCell"];
    UIView * contentView = cell.contentView;
    double x = 45;
    BOOL hasTransitLeg = FALSE;
    
    OBAStopIconFactory * factory = _appContext.stopIconFactory;
    NSMutableArray * routes = [[NSMutableArray alloc] init];

    for( OBALegV2 * leg in itinerary.legs ) {
        OBATransitLegV2 * transitLeg = leg.transitLeg;
        
        if( transitLeg && transitLeg.fromStop) {
            
            UIImage * img = [factory getModeIconForRoute:transitLeg.trip.route];
            UIImageView * imageView = [[UIImageView alloc] initWithImage:img];
            imageView.frame = CGRectMake(x, 7, CGRectGetWidth(imageView.frame)/2, CGRectGetHeight(imageView.frame)/2);            
            [contentView addSubview:imageView];
            x = CGRectGetMaxX(imageView.frame) + 5;
            [imageView release];
            
            UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(x, 8, 22, 15)];
            label.text = [OBAPresentation getRouteShortNameForTransitLeg:transitLeg];
            label.font = [UIFont boldSystemFontOfSize:12];
            [label sizeToFit];
            [contentView addSubview:label];
            x = CGRectGetMaxX(label.frame) + 5;
            [label release];
            
            hasTransitLeg = TRUE;
            [routes addObject:transitLeg.trip.route];
        }
    }
    
    if (! hasTransitLeg) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(x, 8, 22, 15)];
        label.text = @"Walk";
        label.font = [UIFont boldSystemFontOfSize:12];
        [label sizeToFit];
        [contentView addSubview:label];
        [label release];
        cell.modeImage.image = [factory getModeIconForRouteIconType:@"Walk" selected:selected];
    }
    else {
        NSString * routeIconType = [factory getRouteIconTypeForRoutes:routes];
        cell.modeImage.image = [factory getModeIconForRouteIconType:routeIconType selected:selected];
        [routes release];
    }
    
    cell.selectionTarget = self;
    cell.selectionAction = @selector(onItinerarySelection:);
    cell.itinerary = itinerary;
    
    NSString * endTime = [_timeFormatter stringFromDate:itinerary.endTime];
    NSTimeInterval interval = [itinerary.endTime timeIntervalSinceDate:itinerary.startTime];
    NSInteger mins = interval / 60;
    NSString * duration = @"";
    if( mins >= 60 ) {
        NSInteger hours = mins / 60;
        mins = mins % 60;
        duration = [NSString stringWithFormat:@"%d hrs % mins",hours,mins];
    }
    else {
        duration = [NSString stringWithFormat:@"%d mins",mins];
    }
    
    cell.summaryLabel.text = [NSString stringWithFormat:@"Arrive at %@ - %@", endTime, duration];
    
    OBATimeStruct t = [self getTimeForItineraryStart:itinerary];
    [self applyTime:t toTimeLabels:cell];
    
    return cell;
}

- (UITableViewCell*) createCellForStartTrip:(OBATripState*)state includeDetail:(BOOL)includeDetail {
    
    NSDate * startTime = state.itinerary.startTime;
    
    OBAStartTripTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBAStartTripTableViewCell"];
    NSTimeInterval interval = [startTime timeIntervalSinceNow];
    NSInteger mins = interval / 60;
    
    if( includeDetail )
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    if( state.isLateStartTime )
        cell.backgroundColor = [UIColor yellowColor];
    else
        cell.backgroundColor = [UIColor whiteColor];
    
    if( mins < -50 ) {
        cell.statusLabel.text = @"Should've started your trip at:";
    }
    else if( -50 <= mins && mins < -1 ) {
        cell.statusLabel.text = @"Should've started your trip mins ago:";
    }
    else if( -1 <= mins && mins <= 1 ) {
        cell.statusLabel.text = @"Start your trip:";
    }
    else if( 1 < mins && mins <= 50 ) {
        cell.statusLabel.text = @"Start your trip in:";
    }
    else if( 50 < mins ) {
        cell.statusLabel.text = @"Start your trip at:";
    }
    
    OBATimeStruct t = [self getTimeForItineraryStart:state.itinerary];
    [self applyTime:t toTimeLabels:cell];
    
    return cell;
}

- (UITableViewCell*) createCellForVehicleDeparture:(OBATransitLegV2*)transitLeg itinerary:(OBAItineraryV2*)itinerary includeDetail:(BOOL)includeDetail selected:(BOOL)selected {
    
    OBAVehicleDepartureTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBAVehicleDepartureTableViewCell"];

    OBATimeStruct t = [self getTimeForPredictedTime:transitLeg.predictedDepartureTime scheduledTime:transitLeg.scheduledDepartureTime];

    OBAStopIconFactory * factory = _appContext.stopIconFactory;
    cell.modeImage.image = [factory getModeIconForRoute:transitLeg.trip.route selected:selected];
    
	cell.destinationLabel.text = [OBAPresentation getTripHeadsignForTransitLeg:transitLeg];
	cell.routeLabel.text = [OBAPresentation getRouteShortNameForTransitLeg:transitLeg];
	cell.statusLabel.text = [self getStatusLabelForTransitLeg:transitLeg time:t];

    [self applyTime:t toTimeLabels:cell];
    
    cell.selectionTarget = self;
    cell.selectionAction = @selector(onItinerarySelection:);
    cell.itinerary = itinerary;
    
    if( includeDetail )
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
	
    return cell;
}

- (UITableViewCell*) createCellForVehicleArrival:(OBATransitLegV2*)transitLeg itinerary:(OBAItineraryV2*)itinerary includeDetail:(BOOL)includeDetail selected:(BOOL)selected {
    OBAVehicleArrivalTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBAVehicleArrivalTableViewCell"];
    
    OBATimeStruct t = [self getTimeForPredictedTime:transitLeg.predictedArrivalTime scheduledTime:transitLeg.scheduledArrivalTime];
    
    OBAStopIconFactory * factory = _appContext.stopIconFactory;
    cell.modeImage.image = [factory getModeIconForRouteIconType:@"Walk" selected:selected];

	cell.destinationLabel.text = [OBAPresentation getTripHeadsignForTransitLeg:transitLeg];
	cell.statusLabel.text = [self getStatusLabelForTransitLeg:transitLeg time:t];
    
    [self applyTime:t toTimeLabels:cell];
    
    cell.selectionTarget = self;
    cell.selectionAction = @selector(onItinerarySelection:);
    cell.itinerary = itinerary;
	
    if( includeDetail )
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    

    return cell;
}

@end



@implementation OBATripStateTableViewCellFactory (Private)

- (OBATripStateCellIndexPath*) getCellIndexForTripState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath {
   
    NSInteger index = 0;
    
    
    if( state.noResultsFound ) {
        if (indexPath.row == index )
            return [OBATripStateCellIndexPath indexPathWithType:OBATripStateCellTypeNoResultsFound];
        index++;
    }
    
    if (state.type == OBATripStateTypeItineraries) {
        NSUInteger row = indexPath.row - index;
        if( row < [state.itineraries count] )
           return [OBATripStateCellIndexPath indexPathWithType:OBATripStateCellTypeItinerary row:row];
        index += [state.itineraries count];
    }

    
    if( state.showStartTime ) {
        if( indexPath.row == index )
            return [OBATripStateCellIndexPath indexPathWithType:OBATripStateCellTypeStartTime];
        index++;
    }
    
    if( state.walkToStop ) {
        if( indexPath.row == index )
            return [OBATripStateCellIndexPath indexPathWithType:OBATripStateCellTypeWalkToStop];
        index++;
    }
    
    if( state.walkToPlace ) {
        if( indexPath.row == index )
            return [OBATripStateCellIndexPath indexPathWithType:OBATripStateCellTypeWalkToPlace];
        index++;
    }
    
    if (state.stop) {
        if (indexPath.row == index)
            return [OBATripStateCellIndexPath indexPathWithType:OBATripStateCellTypeStop];
        index++;
    }
    
    NSUInteger departureIndex = indexPath.row - index;
    if( departureIndex < [state.departures count] )
        return [OBATripStateCellIndexPath indexPathWithType:OBATripStateCellTypeDeparture row:departureIndex];
    index += [state.departures count];
    
    if( state.ride ) {
        if( indexPath.row == index )
            return [OBATripStateCellIndexPath indexPathWithType:OBATripStateCellTypeRide];
        index++;
    }
    
    NSUInteger arrivalIndex = indexPath.row - index;
    if( arrivalIndex < [state.arrivals count] )
        return [OBATripStateCellIndexPath indexPathWithType:OBATripStateCellTypeArrival row:arrivalIndex];
    index += [state.arrivals count];
    
    return [OBATripStateCellIndexPath indexPathWithType:OBATripStateCellTypeNone];
}

- (UITableViewCell*) createCellForPlanYourTrip {
    return [self getOrCreateCellFromNibNamed:@"OBAPlanYourTripTableViewCell"];	
}

- (UITableViewCell*) createCellForWalkToStop:(OBAStopV2*)stop {
    OBAWalkToLocationTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBAWalkToLocationTableViewCell"];
    cell.destinationLabel.text = stop.name;
    NSMutableString * details = [NSMutableString stringWithFormat:@"Stop # %@", stop.code];
    if( stop.direction ) {
        NSString * label = [_directions objectForKey:stop.direction];
        if( label ) {
            [details appendFormat:@" - %@ bound",label];
        }
    }
    cell.destinationDetailLabel.text = details;
    return cell;
}

- (UITableViewCell*) createCellForWalkToPlace:(OBAPlace*)place {
    OBAWalkToLocationTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBAWalkToLocationTableViewCell"];
    cell.destinationLabel.text = place.name;
    cell.destinationDetailLabel.text = @"";
    return cell;
}

- (UITableViewCell*) createCellForStop:(OBAStopV2*)stop {
    OBAWalkToLocationTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBAWalkToLocationTableViewCell"];
    cell.destinationLabel.text = stop.name;
    NSMutableString * details = [NSMutableString stringWithFormat:@"Stop # %@", stop.code];
    if( stop.direction ) {
        NSString * label = [_directions objectForKey:stop.direction];
        if( label ) {
            [details appendFormat:@" - %@ bound",label];
        }
    }
    cell.destinationDetailLabel.text = details;
    
    OBAStopIconFactory * factory = _appContext.stopIconFactory;
    cell.locationImage.image = [factory getIconForStop:stop includeDirection:FALSE];
    return cell;
}


- (UITableViewCell*) createCellForVehicleRide:(OBATransitLegV2*)transitLeg {
    OBAVehicleRideTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBAVehicleRideTableViewCell"];
    
	cell.destinationLabel.text = [OBAPresentation getTripHeadsignForTransitLeg:transitLeg];
	cell.routeLabel.text = [OBAPresentation getRouteShortNameForTransitLeg:transitLeg];
    cell.statusLabel.text = @"What do we say here?";
    
    return cell;
}

- (OBATimeStruct) getTimeForItineraryStart:(OBAItineraryV2*)itinerary {

    OBATransitLegV2 * departure = nil;
    for (OBALegV2 * leg in itinerary.legs ) {
        if (leg.transitLeg) {
            departure = leg.transitLeg;
            break;
        }
    }
    
    NSDate * predictedTime = nil;
    NSDate * scheduledTime = nil;

    if (departure && departure.fromStopId && departure.predictedDepartureTime > 0) {
        NSTimeInterval delta = (departure.scheduledDepartureTime - departure.predictedDepartureTime) / 1000;
        predictedTime = itinerary.startTime;
        scheduledTime = [NSDate dateWithTimeInterval:delta sinceDate:predictedTime];
    }
    else {
        scheduledTime = itinerary.startTime;
    }
    
    long long predicted = [predictedTime timeIntervalSince1970] * 1000;
    long long scheduled = [scheduledTime timeIntervalSince1970] * 1000;

    return [self getTimeForPredictedTime:predicted scheduledTime:scheduled];
}

- (OBATimeStruct) getTimeForPredictedTime:(long long)predictedTime scheduledTime:(long long)scheduledTime {
    
    long long bestTime = scheduledTime;
    if( predictedTime > 0 )
        bestTime = predictedTime;
    NSDate * bestTimeAsDate = [NSDate dateWithTimeIntervalSince1970:(bestTime / 1000)];
    NSTimeInterval interval = [bestTimeAsDate timeIntervalSinceNow];
	int minutes = interval / 60;
    BOOL isNow = abs(minutes) <=1;
    
    OBATimeStruct t;
    t.predictedTime = predictedTime;
    t.scheduledTime = scheduledTime;
    t.bestTime = bestTimeAsDate;
    t.minutes = minutes;
    t.isNow = isNow;
    return t;
}

- (void) applyTime:(OBATimeStruct)t toTimeLabels:(id<OBAHasTimeLabels>)cell {
    cell.timeLabel.text = [self getMinutesLabelForTime:t];
    cell.timeLabel.textColor = [self getMinutesColorForTime:t];    
    cell.minutesLabel.hidden = t.isNow;
}

- (NSString*) getMinutesLabelForTime:(OBATimeStruct)t {
	if(t.isNow)
		return @"NOW";
	else
		return [NSString stringWithFormat:@"%d",t.minutes];
}

- (UIColor*) getMinutesColorForTime:(OBATimeStruct)t {
    if( t.predictedTime > 0 ) {
		double diff = (t.predictedTime - t.scheduledTime) / ( 1000.0 * 60.0);			
		if( diff < -1.5) {
			return [UIColor redColor];
		}
		else if( diff < 1.5 ) {
			return [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
		}
		else {
			return [UIColor blueColor];
		}
	}
	else {
		return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];;
	}
}

- (NSString*) getDepartureStatusLabelForTransitLeg:(OBATransitLegV2*)transitLeg time:(OBATimeStruct)t {
    return [self getStatusLabelForTransitLeg:transitLeg time:t];
}

- (NSString*) getStatusLabelForTransitLeg:(OBATransitLegV2*)transitLeg time:(OBATimeStruct)t {
    
    if( transitLeg.frequency ) {
		OBAFrequencyV2 * freq = transitLeg.frequency;
		int headway = freq.headway / 60;
		
		NSDate * now = [NSDate date];
		NSDate * startTime = [NSDate dateWithTimeIntervalSince1970:(freq.startTime / 1000)];
		NSDate * endTime = [NSDate dateWithTimeIntervalSince1970:(freq.endTime / 1000)];
		
		if ([now compare:startTime]  == NSOrderedAscending) {
			return [NSString stringWithFormat:@"Every %d mins from %@",headway,[_timeFormatter stringFromDate:startTime]];
		}
		else {
			return [NSString stringWithFormat:@"Every %d mins until %@",headway,[_timeFormatter stringFromDate:endTime]];
		}
	}

    NSString * status;
	
	if( t.predictedTime > 0 ) {
        double diff = (t.predictedTime - t.scheduledTime) / ( 1000.0 * 60.0);
        int minDiff = (int) abs(diff);
        if( diff < -1.5) {
            if( t.minutes < 0 )
                status = [NSString stringWithFormat:@"departed %d min early",minDiff];
            else
                status = [NSString stringWithFormat:@"%d min early",minDiff];
        }
        else if( diff < 1.5 ) {
            if( t.minutes < 0 )
                status = @"departed on time";
            else
                status = @"on time";
        }
        else {
            if( t.minutes < 0 )
                status = [NSString stringWithFormat:@"departed %d min late",minDiff];
            else
                status = [NSString stringWithFormat:@"%d min delay",minDiff];
        }
	}
	else {
		if( t.minutes < 0 )
			status = @"scheduled departure";
		else
			status = @"scheduled arrival";
	}
	
	return [NSString stringWithFormat:@"%@ - %@",[_timeFormatter stringFromDate:t.bestTime],status];	
}

- (id) getOrCreateCellFromNibNamed:(NSString*)cellId {

    // Try to retrieve from the table view a now-unused cell with the given identifier
	UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellId];
	
	// If no cell is available, create a new one using the given identifier
	if (cell == nil) {
		NSArray * nib = [[NSBundle mainBundle] loadNibNamed:cellId owner:nil options:nil];
		cell = [nib objectAtIndex:0];
	}
	
	return cell;
}

- (void) onItinerarySelection:(id)sender {
    id<OBAHasItinerarySelectionButton> source = sender;
    if (source.itinerary) {
        [_appContext.tripController selectItinerary:source.itinerary matchPreviousItinerary:TRUE];
    }
}

@end