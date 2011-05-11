#import "OBAReportProblemWithPlannedTripViewController.h"
#import "OBAListSelectionViewController.h"
#import "OBATextEditViewController.h"
#import "OBALabelAndSwitchTableViewCell.h"
#import "OBALabelAndTextFieldTableViewCell.h"
#import "OBALogger.h"
#import "SBJSON.h"
#import "OBAReportProblemWithPlannedTripV2.h"


typedef enum {
	OBASectionTypeNone,	
	OBASectionTypeProblem,
	OBASectionTypeComment,
	OBASectionTypeSubmit,
	OBASectionTypeNotes
} OBASectionType;


@interface OBAReportProblemWithPlannedTripViewController (Private)

- (void) addProblemWithId:(NSString*)problemId name:(NSString*)problemName;

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;
- (NSUInteger) sectionIndexForType:(OBASectionType)type;

- (void) submit;
- (NSString*) getProblemAsData;

@end


@implementation OBAReportProblemWithPlannedTripViewController

#pragma mark -
#pragma mark Initialization

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
		_appContext = [appContext retain];
        
		self.navigationItem.title = @"Report a Problem";
        
		_problemIds = [[NSMutableArray alloc] init];
		_problemNames = [[NSMutableArray alloc] init];
        
		[self addProblemWithId:@"missing_trip" name:@"Missing an expected trip"];
		[self addProblemWithId:@"other" name:@"Other"];
		
		_activityIndicatorView = [[OBAModalActivityIndicator alloc] init];		
    }
    return self;
}

- (void)dealloc {
	[_appContext release];
    [_problemIds release];
	[_problemNames release];
	[_comment release];
	[_activityIndicatorView release];
    [super dealloc];
}


#pragma mark UIViewController

-(void)viewDidLoad {
	self.navigationItem.backBarButtonItem.title = @"Problem";
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeProblem:
			return @"What's the problem?";
		case OBASectionTypeComment:
			return @"Optional - Comment:";
		case OBASectionTypeNotes:
			return @"Your reports help OneBusAway find and fix problems with the system.";
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch( sectionType ) {
		case OBASectionTypeProblem:
			return 1;
		case OBASectionTypeComment:
			return 1;
		case OBASectionTypeSubmit:
			return 1;
		case OBASectionTypeNotes:
			return 0;
		case OBASectionTypeNone:
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeProblem: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];			
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = [_problemNames objectAtIndex:_problemIndex];
			return cell;			
		}
		case OBASectionTypeComment: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];			
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			if (_comment && [_comment length] > 0) {
				cell.textLabel.textColor = [UIColor blackColor];
				cell.textLabel.text = _comment;
			}
			else {
				cell.textLabel.textColor = [UIColor grayColor];
				cell.textLabel.text = @"Touch to edit";
			}
			
			return cell;
		}
            
		case OBASectionTypeSubmit: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];			
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.text = @"Submit";
			return cell;
		}
		default:	
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	switch (sectionType) {
		case OBASectionTypeProblem: {
			NSIndexPath * selectedIndex = [NSIndexPath indexPathForRow:_problemIndex inSection:0];			
			OBAListSelectionViewController * vc = [[OBAListSelectionViewController alloc] initWithValues:_problemNames selectedIndex:selectedIndex];
			vc.target = self;
			vc.action = @selector(setProblem:);
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			break;
		}
			
		case OBASectionTypeComment: {
			OBATextEditViewController * vc = [OBATextEditViewController pushOntoViewController:self withText:_comment withTitle:@"Comment"];
			vc.target = self;
			vc.action = @selector(setComment:);
			break;
		}
			
		case OBASectionTypeSubmit: {
			[self submit];
		}
			
		default:
			break;
	}
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
	return YES;
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
	[_activityIndicatorView hide];
	[self.navigationController popToRootViewControllerAnimated:TRUE];
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
	[_activityIndicatorView hide];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
	[_activityIndicatorView hide];
	OBALogSevereWithError(error,@"problem posting problem");
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    
}


#pragma mark Other methods

- (void) setProblem:(NSIndexPath*)indexPath {
	_problemIndex = indexPath.row;
	NSUInteger section = [self sectionIndexForType:OBASectionTypeProblem];
	NSIndexPath * p = [NSIndexPath indexPathForRow:0 inSection:section];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:p] withRowAnimation:UITableViewRowAnimationFade];
}

- (void) setComment:(NSString*)comment {
	_comment = [NSObject releaseOld:_comment retainNew:comment];
	NSUInteger section = [self sectionIndexForType:OBASectionTypeComment];
	NSIndexPath * p = [NSIndexPath indexPathForRow:0 inSection:section];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:p] withRowAnimation:UITableViewRowAnimationFade];
}

@end


@implementation OBAReportProblemWithPlannedTripViewController (Private)

- (void) addProblemWithId:(NSString*)problemId name:(NSString*)problemName {
	[_problemIds addObject:problemId];
	[_problemNames addObject:problemName];
}

- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	switch (section) {
		case 0:
			return OBASectionTypeProblem;
		case 1:
			return OBASectionTypeComment;
		case 2:
			return OBASectionTypeSubmit;
		case 3:
			return OBASectionTypeNotes;
		default:
			return OBASectionTypeNone;
	}
}

- (NSUInteger) sectionIndexForType:(OBASectionType)type {
	switch (type) {
		case OBASectionTypeProblem:
			return 0;
		case OBASectionTypeComment:
			return 1;
		case OBASectionTypeSubmit:
			return 2;
		case OBASectionTypeNotes:
			return 3;
		case OBASectionTypeNone:
		default:
			break;
	}
	return -1;
}

- (void) submit {
    
	OBAReportProblemWithPlannedTripV2 * problem = [[OBAReportProblemWithPlannedTripV2 alloc] init];
    
    OBATripQuery * query = _appContext.tripController.query;
    
    problem.fromLocation = query.placeFrom.location;
    problem.toLocation = query.placeTo.location;
    
    OBATargetTime * targetTime = query.time;
    problem.arriveBy = targetTime.type == OBATargetTimeTypeArriveBy;
    problem.time = targetTime.time;
    if( targetTime.type == OBATargetTimeTypeNow )
        problem.time = [NSDate date];
    
	problem.data = [self getProblemAsData];
	problem.userComment = _comment;
	problem.userLocation = _appContext.locationManager.currentLocation;
    
	[_activityIndicatorView show:self.view];
	[_appContext.modelService reportProblemWithPlannedTrip:problem withDelegate:self withContext:nil];
	
	[problem release];
}

- (NSString*) getProblemAsData {
    
	NSMutableDictionary * p = [[NSMutableDictionary alloc] init];
	[p setObject:[_problemIds objectAtIndex:_problemIndex] forKey:@"code"];
	[p setObject:[_problemNames objectAtIndex:_problemIndex] forKey:@"text"];
	
	SBJSON * json = [[SBJSON alloc] init];
	NSString * v = [json stringWithObject:p];
	[json release];
	[p release];
	return v;	
}

@end