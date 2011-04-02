//
//  OBAPlaceModel.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAPlaceModel.h"
#import "OBAPlace.h"


@interface OBAPlaceModel (Private)

- (BOOL) isPlace:(OBAPlace*)place matchForSearch:(NSString*)text;

@end


@implementation OBAPlaceModel

@synthesize places = _places;

- (id) initWithAppContext:(OBAApplicationContext*)appContext {
    self = [super init];
    if (self) {
        _appContext = [appContext retain];        
    }
    return self;
}

- (void)search:(NSString *)text {

    [self cancel];
    
    [_places release];
    _places = [[NSMutableArray alloc] init];
    
    OBAModelDAO * modelDao = _appContext.modelDao;
    NSArray * bookmarks = modelDao.bookmarks;
    
    [_delegates perform:@selector(modelDidStartLoad:) withObject:self];
    
    OBAPlace * currentLocation = [OBAPlace placeWithCurrentLocation];
    if( [self isPlace:currentLocation matchForSearch:text] )
        [_places addObject:currentLocation];
        
    for( OBAPlace * place in bookmarks ) {
        if( [self isPlace:place matchForSearch:text] )
            [_places addObject:place];
    }
    
    [_delegates perform:@selector(modelDidFinishLoad:) withObject:self];
}

#pragma mark -
#pragma mark TTModel methods

- (NSMutableArray *)delegates {
    if (!_delegates) {
        _delegates = [[NSMutableArray alloc] init];
    }
    return _delegates;
}

- (BOOL)isLoadingMore {
    return NO;
}

- (BOOL)isOutdated {
    return NO;
}

- (BOOL)isLoaded {
    return TRUE;
}

- (BOOL)isLoading {
    return NO;
}

- (BOOL)isEmpty {
    return FALSE;
}

- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more {
}

- (void)invalidate:(BOOL)erase {
}

- (void)cancel {
}

@end


@implementation OBAPlaceModel (Private)

- (BOOL) isPlace:(OBAPlace*)place matchForSearch:(NSString*)text {
    NSRange range = [place.name rangeOfString:text options:NSCaseInsensitiveSearch];
    return range.length;
}

@end