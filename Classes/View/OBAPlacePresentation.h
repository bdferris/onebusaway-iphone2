#import "OBAPlace.h"
#import "Three20UI/Three20UI.h"
#import <AddressBook/AddressBook.h>


@interface OBAPlacePresentation : NSObject {
    
}

+ (TTTableItem*) getPlaceAsItem:(OBAPlace*)place;
+ (OBAPlace*) getAddressBookPersonAsPlace:(ABRecordRef)person withAddressRecord:(NSDictionary*)theDict;

@end
