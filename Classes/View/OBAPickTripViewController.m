//
//  OBAPickTripViewController.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 4/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAPickTripViewController.h"


@implementation OBAPickTripViewController

- (id) initWithAppContext:(OBAApplicationContext*)appContext
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _appContext = [appContext retain];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tripStateTableViewCellFactory = [[OBATripStateTableViewCellFactory alloc] initWithAppContext:_appContext navigationController:self.navigationController tableView:self.tableView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray * itineraries = _appContext.tripController.itineraries;
    NSInteger count = [itineraries count];
    if( count == 0 )
        count++;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray * itineraries = _appContext.tripController.itineraries;
    if( [itineraries count] == 0 ) {
        UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"NoItineraries"];
        cell.textLabel.text = @"No trips found";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        return cell;
    }
    
    OBAItineraryV2 * itinerary = [itineraries objectAtIndex:indexPath.row];
    return [_tripStateTableViewCellFactory createCellForTripSummary:itinerary];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray * itineraries = _appContext.tripController.itineraries;
    if ([itineraries count] == 0) {
        return;
    }
    
    OBAItineraryV2 * itinerary = [itineraries objectAtIndex:indexPath.row];
    
    [_appContext.tripController selectItinerary:itinerary];
}

@end
