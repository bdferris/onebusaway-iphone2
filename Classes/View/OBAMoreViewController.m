//
//  OBAMoreViewController.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAMoreViewController.h"
#import "IASKAppSettingsViewController.h"
#import "OBAReportProblemWithPlannedTripViewController.h"


@implementation OBAMoreViewController

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
    [_appContext retain];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"More";
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0: {
            UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"Cell"];
            cell.textLabel.text = @"Settings";
            cell.imageView.image = [UIImage imageNamed:@"Gear.png"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
        case 1: {
            UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"Cell"];
            cell.textLabel.text = @"Report a problem";
            cell.imageView.image = [UIImage imageNamed:@"AlertGrayscale.png"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
    
        default:
            break;
    }

    return [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"Cell"];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0: {
            IASKAppSettingsViewController * vc = [[IASKAppSettingsViewController alloc] init];
            vc.delegate = _appContext;
            [self.navigationController pushViewController:vc animated:TRUE];
            [vc release];
            break;
        }
        case 1: {
            OBAReportProblemWithPlannedTripViewController * vc = [[OBAReportProblemWithPlannedTripViewController alloc] initWithApplicationContext:_appContext];
            [self.navigationController pushViewController:vc animated:TRUE];
            [vc release];         
            break;
        }
        default:
            break;
    }
}

@end
