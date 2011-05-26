//
//  OBAPlaceModel.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 3/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAPlaceModel.h"
#import "OBAPlace.h"
#import "OBAPlacePresentation.h"


#import <AddressBook/AddressBook.h>

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
    NSArray * recentPlaces = modelDao.recentPlaces;
    
    [_delegates perform:@selector(modelDidStartLoad:) withObject:self];
    
    OBAPlace * currentLocation = [OBAPlace placeWithCurrentLocation];
    if( [self isPlace:currentLocation matchForSearch:text] )
        [_places addObject:currentLocation];
        
    for( OBAPlace * place in bookmarks ) {
        if( [self isPlace:place matchForSearch:text] )
            [_places addObject:place];
    }
    
    for( OBAPlace * place in recentPlaces ) {
        if( [self isPlace:place matchForSearch:text] )
            [_places addObject:place];
    }
    
    ABAddressBookRef addressBook = ABAddressBookCreate();
    
    NSArray * people = (NSArray*) ABAddressBookCopyPeopleWithName(addressBook, (CFStringRef) text);
    
    if( (people != nil) && [people count] > 0 ) {
        
        for (CFIndex index=0; index < [people count]; index++) {

            ABRecordRef person = (ABRecordRef)[people objectAtIndex:index];

            CFStringRef firstName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
            CFStringRef lastName  = ABRecordCopyValue(person, kABPersonLastNameProperty);
            
            ABMultiValueRef multi = ABRecordCopyValue(person, kABPersonAddressProperty);
            CFIndex count = ABMultiValueGetCount(multi);
            
            for(CFIndex i=0;i<count;i++) {
                
                NSDictionary * dict = (NSDictionary *) ABMultiValueCopyValueAtIndex(multi, i);

                OBAPlace * place = [OBAPlacePresentation getAddressBookPersonAsPlace:person withAddressRecord:dict];
                [_places addObject:place];
                
                CFRelease(dict);
            }
            
            if (firstName != nil)
                CFRelease(firstName);

            if (lastName != nil)
                CFRelease(lastName);
            
            CFRelease(multi);
        }
    }
    
    if (people != nil)
        CFRelease(people);
    
    CFRelease(addressBook);
        
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
