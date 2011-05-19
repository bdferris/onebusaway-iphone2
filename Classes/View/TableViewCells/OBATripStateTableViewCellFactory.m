//
//  OBATripStateTableViewCellFactory.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBATripStateTableViewCellFactory.h"
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

- (OBATripStateCellType) getCellTypeForTripState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath;

- (UITableViewCell*) createCellForPlanYourTrip;

- (UITableViewCell*) createCellForWalkToStop:(OBAStopV2*)stop;
- (UITableViewCell*) createCellForWalkToPlace:(OBAPlace*)place;
- (UITableViewCell*) createCellForVehicleRide:(OBATransitLegV2*)transitLeg;

- (OBATimeStruct) getTimeForPredictedTime:(long long)predictedTime scheduledTime:(long long)scheduledTime;
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

    if( state == nil )
        return 1;
    
    NSInteger rows = 0;
    if( state.showTripSummary )
        rows++;
    if( state.noResultsFound )
        rows++;
    if( state.startTime )
        rows++;
    if( state.walkToStop )
        rows++;
    if( state.walkToPlace )
        rows++;
    if( state.departure )
        rows++;
    if( state.ride )
        rows++;
    if( state.arrival )
        rows++;
    
    return rows;
}

- (UITableViewCell*) getCellForState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath {

    if( state == nil )
        return [self createCellForPlanYourTrip];

    OBATripStateCellType cellType = [self getCellTypeForTripState:state indexPath:indexPath];

    switch (cellType) {
        case OBATripStateCellTypeTripSummary:
            return [self createCellForTripSummary:state.itinerary];
        case OBATripStateCellTypeNoResultsFound:
            return [self createCellForNoResultsFound];
        case OBATripStateCellTypeStartTime:
            return [self createCellForStartTrip:state includeDetail:TRUE];
        case OBATripStateCellTypeWalkToStop:
            return [self createCellForWalkToStop:state.walkToStop];
        case OBATripStateCellTypeWalkToPlace:
            return [self createCellForWalkToPlace:state.walkToPlace];
        case OBATripStateCellTypeDeparture:
            return [self createCellForVehicleDeparture:state.departure includeDetail:TRUE];
        case OBATripStateCellTypeRide:
            return [self createCellForVehicleRide:state.ride];
        case OBATripStateCellTypeArrival:
            return [self createCellForVehicleArrival:state.arrival includeDetail:TRUE];
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
    
    OBATripStateCellType cellType = [self getCellTypeForTripState:state indexPath:indexPath];
    
    switch (cellType) {
        case OBATripStateCellTypeTripSummary: {
            OBAPickTripViewController * vc = [[OBAPickTripViewController alloc] initWithAppContext:_appContext];
            [_navigationController pushViewController:vc animated:TRUE];
            [vc release];             
            break;
        }
        case OBATripStateCellTypeNoResultsFound: {
            OBAPlanTripViewController * vc = [[OBAPlanTripViewController alloc] initWithAppContext:_appContext];
            [vc setTripQuery:_appContext.tripController.query];
            [_navigationController pushViewController:vc animated:TRUE];
            [vc release];
            break;
        }
        case OBATripStateCellTypeStartTime:
        case OBATripStateCellTypeDeparture:
        case OBATripStateCellTypeArrival:
        {
            OBAAlarmViewController * vc = [[OBAAlarmViewController alloc] initWithAppContext:_appContext tripState:state cellType:cellType ];
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

- (UITableViewCell*) createCellForTripSummary:(OBAItineraryV2*)itinerary {
    
    OBATripSummaryTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBATripSummaryTableViewCell"];
    UIView * contentView = cell.contentView;
    double x = 7;
    BOOL hasTransitLeg = FALSE;

    for( OBALegV2 * leg in itinerary.legs ) {
        OBATransitLegV2 * transitLeg = leg.transitLeg;
        
        if( transitLeg && transitLeg.fromStop) {
            
            OBAStopIconFactory * factory = _appContext.stopIconFactory;
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
        }
    }
    
    if (! hasTransitLeg) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(x, 8, 22, 15)];
        label.text = @"Walk";
        label.font = [UIFont boldSystemFontOfSize:12];
        [label sizeToFit];
        [contentView addSubview:label];
        [label release];
    }
    
    NSString * startTime = [_timeFormatter stringFromDate:itinerary.startTime];
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
    
    cell.summaryLabel.text = [NSString stringWithFormat:@"%@ - %@ - %@", startTime, endTime, duration];
    
    return cell;
}

- (UITableViewCell*) createCellForStartTrip:(OBATripState*)state includeDetail:(BOOL)includeDetail {
    
    NSDate * startTime = state.startTime;
    
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
        cell.timeLabel.text = [_timeFormatter stringFromDate:startTime];
        cell.statusLabel.text = @"Should've started your trip at:";
        cell.minutesLabel.hidden = TRUE;
    }
    else if( -50 <= mins && mins < -1 ) {
        cell.timeLabel.text = [NSString stringWithFormat:@"%d", mins];
        cell.statusLabel.text = @"Should've started your trip mins ago:";
        cell.minutesLabel.hidden = FALSE;
    }
    else if( -1 <= mins && mins <= 1 ) {
        cell.timeLabel.text = @"NOW";
        cell.statusLabel.text = @"Start your trip:";
        cell.minutesLabel.hidden = TRUE;
    }
    else if( 1 < mins && mins <= 50 ) {
        cell.timeLabel.text = [NSString stringWithFormat:@"%d", mins];
        cell.statusLabel.text = @"Start your trip in:";
        cell.minutesLabel.hidden = FALSE;
    }
    else if( 50 < mins ) {
        cell.timeLabel.text = [_timeFormatter stringFromDate:startTime];
        cell.statusLabel.text = @"Start your trip at:";
        cell.minutesLabel.hidden = TRUE;
    }
    
    return cell;
}

- (UITableViewCell*) createCellForVehicleDeparture:(OBATransitLegV2*)transitLeg includeDetail:(BOOL)includeDetail {
    
    OBAVehicleDepartureTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBAVehicleDepartureTableViewCell"];
    
    OBATimeStruct t = [self getTimeForPredictedTime:transitLeg.predictedDepartureTime scheduledTime:transitLeg.scheduledDepartureTime];
    
	cell.destinationLabel.text = [OBAPresentation getTripHeadsignForTransitLeg:transitLeg];
	cell.routeLabel.text = [OBAPresentation getRouteShortNameForTransitLeg:transitLeg];
	cell.statusLabel.text = [self getStatusLabelForTransitLeg:transitLeg time:t];
    
    cell.timeLabel.text = [self getMinutesLabelForTime:t];
    cell.timeLabel.textColor = [self getMinutesColorForTime:t];    
    cell.minutesLabel.hidden = t.isNow;
    
    if( includeDetail )
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
	
    return cell;
}

- (UITableViewCell*) createCellForVehicleArrival:(OBATransitLegV2*)transitLeg includeDetail:(BOOL)includeDetail {
    OBAVehicleArrivalTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBAVehicleArrivalTableViewCell"];
    
    OBATimeStruct t = [self getTimeForPredictedTime:transitLeg.predictedArrivalTime scheduledTime:transitLeg.scheduledArrivalTime];
    
	cell.destinationLabel.text = transitLeg.toStop.name;
	cell.statusLabel.text = [self getStatusLabelForTransitLeg:transitLeg time:t];
    
    cell.timeLabel.text = [self getMinutesLabelForTime:t];
    cell.timeLabel.textColor = [self getMinutesColorForTime:t];
    cell.minutesLabel.hidden = t.isNow;
	
    if( includeDetail )
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

@end



@implementation OBATripStateTableViewCellFactory (Private)

- (OBATripStateCellType) getCellTypeForTripState:(OBATripState*)state indexPath:(NSIndexPath*)indexPath {
   
    NSInteger index = 0;
    
    if( state.noResultsFound ) {
        if (indexPath.row == index )
            return OBATripStateCellTypeNoResultsFound;
        index++;
    }
    
    if( state.showTripSummary ) {
        if( indexPath.row == index )
            return OBATripStateCellTypeTripSummary;
        index++;
    }
    
    if( state.startTime ) {
        if( indexPath.row == index )
            return OBATripStateCellTypeStartTime;
        index++;
    }
    
    if( state.walkToStop ) {
        if( indexPath.row == index )
            return OBATripStateCellTypeWalkToStop;
        index++;
    }
    
    if( state.walkToPlace ) {
        if( indexPath.row == index )
            return OBATripStateCellTypeWalkToPlace;
        index++;
    }
    
    if( state.departure ) {
        if( indexPath.row == index )
            return OBATripStateCellTypeDeparture;
        index++;
    }
    
    if( state.ride ) {
        if( indexPath.row == index )
            return OBATripStateCellTypeRide;
        index++;
    }
    
    if( state.arrival ) {
        if( indexPath.row == index )
            return OBATripStateCellTypeArrival;
        index++;
    }
    
    return OBATripStateCellTypeNone;
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

- (UITableViewCell*) createCellForVehicleRide:(OBATransitLegV2*)transitLeg {
    OBAVehicleRideTableViewCell * cell = [self getOrCreateCellFromNibNamed:@"OBAVehicleRideTableViewCell"];
    
	cell.destinationLabel.text = [OBAPresentation getTripHeadsignForTransitLeg:transitLeg];
	cell.routeLabel.text = [OBAPresentation getRouteShortNameForTransitLeg:transitLeg];
    cell.statusLabel.text = @"What do we say here?";
    
    return cell;
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

@end