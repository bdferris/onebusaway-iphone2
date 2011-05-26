/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAApplicationContext.h"
#import "OBANavigationTargetAware.h"
#import "OBAPlace.h"
#import "OBACurrentTravelModeController.h"
#import "OBAGeocoderController.h"

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>


@protocol OBABookmarksViewControllerDelegate <NSObject>

- (void) placeBookmarkSelected:(OBAPlace*)place;

@end

typedef enum {
    OBABookmarksViewControllerModeBookmarks,
    OBABookmarksViewControllerModeRecent,
    OBABookmarksViewControllerModeContacts
} OBABookmarksViewControllerMode;


@interface OBABookmarksViewController : UITableViewController <OBACurrentTravelModeDelegate, ABPeoplePickerNavigationControllerDelegate, UINavigationControllerDelegate, OBAGeocoderControllerDelegate> {
    
	OBAApplicationContext * _appContext;
	OBABookmarksViewControllerMode _mode;
    NSArray * _currentLocations;
	NSArray * _bookmarks;
    NSArray * _recents;
    BOOL _includeCurrentLocation;
	UIBarButtonItem * _bookmarkEditButton;
    UIBarButtonItem * _recentClearButton;
    UISegmentedControl * _segmented;
    ABPeoplePickerNavigationController * _peoplePicker;
    OBAGeocoderController * _geocoder;
}

+ (void) showBookmarksViewControllerWithAppContext:(OBAApplicationContext*)appContext parent:(UINavigationController*)parent delegate:(id<OBABookmarksViewControllerDelegate>)delegate includeCurrentLocation:(BOOL)includeCurrentLocation;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext;

@property (nonatomic,retain) IBOutlet OBAApplicationContext * appContext;
@property (nonatomic,retain) IBOutlet id<OBABookmarksViewControllerDelegate> delegate;
@property (nonatomic) BOOL includeCurrentLocation;
@property (nonatomic) OBABookmarksViewControllerMode mode;

@end
