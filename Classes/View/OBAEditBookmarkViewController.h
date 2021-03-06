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
#import "OBAPlace.h"


typedef enum {
	OBABookmarkEditNew=0,
	OBABookmarkEditExisting=1
} OBABookmarkEditType;

@interface OBAEditBookmarkViewController : UITableViewController <OBAModelServiceDelegate> {
	OBAApplicationContext * _appContext;
	OBABookmarkEditType _editType;
	OBAPlace * _bookmark;
	NSMutableArray * _requests;
	NSMutableDictionary * _stops;
	UITextField * _textField;
    
    id<NSObject> _onSuccessTarget;
    SEL _onSuccessAction;
    
    id<NSObject> _onCancelTarget;
    SEL _onCancelAction;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext bookmark:(OBAPlace*)bookmark editType:(OBABookmarkEditType)editType;

- (IBAction) onCancelButton:(id)sender;
- (IBAction) onSaveButton:(id)sender;

- (void) setOnSuccessTarget:(id<NSObject>)target action:(SEL)action;
- (void) setOnCancelTarget:(id<NSObject>)target action:(SEL)action;

@property (nonatomic) BOOL popToRootOnCompletion;

@end

