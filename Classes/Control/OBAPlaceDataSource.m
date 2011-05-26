//
//  OBAPlaceSearchModel.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAPlaceDataSource.h"
#import "OBAPlaceModel.h"
#import "OBAPlace.h"
#import "OBAPlacePresentation.h"


@implementation OBAPlaceDataSource

- (id) initWithAppContext:(OBAApplicationContext*)appContext {
    self = [super init];
    if (self) {
        _placeModel = [[OBAPlaceModel alloc] initWithAppContext:appContext];
        self.model = _placeModel;
    }
    return self;
}

- (void)dealloc {
    [_model release];
    [super dealloc];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

//- (NSArray *)sectionIndexTitlesForTableView:(UITableView*)tableView {
//    return [TTTableViewDataSource lettersForSectionsWithSearch:YES summary:NO];
//}

#pragma mark -
#pragma mark TTTableViewDataSource methods

- (void)tableViewDidLoadModel:(UITableView*)tableView {
    self.items = [NSMutableArray array];
    self.sections = [NSMutableArray array];
    
    NSMutableArray * itemsForSection = [NSMutableArray array];
    
    for (OBAPlace *place in _placeModel.places) {
        TTTableItem *item = [OBAPlacePresentation getPlaceAsItem:place];
        [itemsForSection addObject:item];
    }

    [self.sections addObject:@"Matches:"];
    [self.items addObject:itemsForSection];
}

- (void)search:(NSString*)text {
    [_placeModel search:text];
}
@end
