//
//  OBAPlacePresentation.m
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OBAPlacePresentation.h"


@implementation OBAPlacePresentation

+ (TTTableItem*) getPlaceAsItem:(OBAPlace*)place {
    
    NSString * name = place.name;
    
    if (place.address != nil) {
        name = [NSString stringWithFormat:@"%@: %@", name, place.address];
    }

    /*
    if ([name length] > 18) {
        name = [NSString stringWithFormat:@"%@...", [name substringToIndex:15]];
    }
    */
    
    TTTableItem *item = [TTTableTextItem itemWithText:name URL:nil];
    item.userInfo = place;
    return item;
}

+ (OBAPlace*) getAddressBookPersonAsPlace:(ABRecordRef)person withAddressRecord:(NSDictionary*)theDict {
    
    OBAPlace * place = [[[OBAPlace alloc] init] autorelease];
    
    place.type = OBAPlaceTypeContact;
    
    CFStringRef firstName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    CFStringRef lastName  = ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    place.name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];

    if (firstName)
        CFRelease(firstName);

    if (lastName)
        CFRelease(lastName);
    
    const NSUInteger theCount = [theDict count];
    NSString *keys[theCount];
    NSString *values[theCount];
    [theDict getObjects:values andKeys:keys];
    
    // Set the address label's text.
    NSMutableString * address = [[NSMutableString alloc] init];
    
    NSString * street = [theDict objectForKey:(NSString *)kABPersonAddressStreetKey];
    if (street) {
        [address appendString:@" "];
        [address appendString:street];
    }
    
    NSString * city = [theDict objectForKey:(NSString *)kABPersonAddressCityKey];
    if (city) {
        [address appendString:@" "];
        [address appendString:city];
    }
    
    NSString * state = [theDict objectForKey:(NSString *)kABPersonAddressStateKey];
    if (state) {
        [address appendString:@" "];
        [address appendString:state];
    }

    NSString * zip = [theDict objectForKey:(NSString *)kABPersonAddressZIPKey];
    if (zip) {
        [address appendString:@" "];
        [address appendString:zip];
    }

    NSString * country = [theDict objectForKey:(NSString *)kABPersonAddressCountryKey];
    if (country) {
        [address appendString:@" "];
        [address appendString:country];
    }

    place.address = [address stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    
    return place;
}

@end
