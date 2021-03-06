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

#import "OBAEditBookmarkViewController.h"
#import "OBALogger.h"
#import "OBATextFieldTableViewCell.h"


@implementation OBAEditBookmarkViewController

@synthesize popToRootOnCompletion;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext bookmark:(OBAPlace*)bookmark editType:(OBABookmarkEditType)editType {

    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
		self.tableView.scrollEnabled = FALSE;

		_appContext = [appContext retain];
		_bookmark = [bookmark retain];
		_editType = editType;

		_requests = [[NSMutableArray alloc] initWithCapacity:[_bookmark.stopIds count]];
		_stops = [[NSMutableDictionary alloc] init];

		UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancelButton:)];
		[self.navigationItem setLeftBarButtonItem:cancelButton];
		[cancelButton release];
		
		UIBarButtonItem * saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSaveButton:)];
		[self.navigationItem setRightBarButtonItem:saveButton];
		[saveButton release];
		
		switch(_editType) {
			case OBABookmarkEditNew:
				self.navigationItem.title = @"Add Bookmark";
				break;
			case OBABookmarkEditExisting:
				self.navigationItem.title = @"Edit Bookmark";
				break;
		}
    }
	
    return self;
}

- (void)dealloc {
	[_appContext release];
	[_bookmark release];
	[_stops release];
	[_requests release];
    [_onSuccessTarget release];
    [_onCancelTarget release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
	
	
	OBAModelService * service = _appContext.modelService;
	NSArray * stopIds = _bookmark.stopIds;
	for( NSUInteger i=0; i<[stopIds count]; i++) {
		NSString * stopId = [stopIds objectAtIndex:i];
		NSNumber * index = [NSNumber numberWithInt:i];
		id<OBAModelServiceRequest> request = [service requestStopForId:stopId withDelegate:self withContext:index];
		[_requests addObject:request];
	}
}

#pragma mark OBAModelServiceRequest

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
	
	OBAEntryWithReferencesV2 * entry = obj;
	OBAStopV2 * stop = entry.entry;
	
	NSNumber * num = context;
	NSUInteger index = [num intValue];
	
	if( stop ) {
		[_stops setObject:stop forKey:stop.stopId];
		NSIndexPath * path = [NSIndexPath indexPathForRow:index+1 inSection:0];
		NSArray * indexPaths = [NSArray arrayWithObject:path];
		[self.tableView  reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
	}
	
	[_requests removeObject:request];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 1;
    if( [_bookmark.stopIds count] > 0)
        count++;
	return count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	if( indexPath.row == 0 ) {
		OBATextFieldTableViewCell * cell =  [OBATextFieldTableViewCell getOrCreateCellForTableView:tableView];
		cell.textField.text = _bookmark.name;
		_textField = cell.textField;
		[_textField becomeFirstResponder];
		[tableView addSubview:cell]; // make keyboard slide in/out from right.
		return cell;
	}
	else {
		UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
		
		NSString * stopId = [_bookmark.stopIds objectAtIndex:indexPath.row-1];
		OBAStopV2 * stop = [_stops objectForKey:stopId];
		if( stop )
			cell.textLabel.text = [NSString stringWithFormat:@"Stop # %@ - %@",stop.code,stop.name];
		else
			cell.textLabel.text = @"Loading stop info...";
		
		cell.textLabel.font = [UIFont systemFontOfSize: 12];
		cell.textLabel.textColor = [UIColor grayColor];
		cell.selectionStyle =  UITableViewCellSelectionStyleNone;
		return cell;
	}
}

- (IBAction) onCancelButton:(id)sender {
    
    if (self.popToRootOnCompletion)
        [self.navigationController popToRootViewControllerAnimated:TRUE];
    else
        [self.navigationController popViewControllerAnimated:TRUE];

    if (_onCancelTarget && _onCancelAction)
        [_onCancelTarget performSelector:_onCancelAction withObject:self];
}

- (IBAction) onSaveButton:(id)sender {
		
	OBAModelDAO * dao = _appContext.modelDao;
	NSError * error = nil;
	
	_bookmark.name = _textField.text;
	
	switch (_editType ) {
		case OBABookmarkEditNew:
			[dao addNewBookmark:_bookmark error:&error];
			break;
		case OBABookmarkEditExisting:
			[dao saveExistingBookmark:_bookmark error:&error];
			break;
	}

	if( error )
		OBALogSevereWithError(error,@"Error saving bookmark: name=%@",_bookmark.name);
	
    if (self.popToRootOnCompletion)
        [self.navigationController popToRootViewControllerAnimated:TRUE];
    else
        [self.navigationController popViewControllerAnimated:TRUE];

    if (_onSuccessTarget && _onSuccessAction)
        [_onSuccessTarget performSelector:_onSuccessAction withObject:self];
}

- (void) setOnSuccessTarget:(id)target action:(SEL)action {
    _onSuccessTarget = [NSObject releaseOld:_onSuccessTarget retainNew:target];
    _onSuccessAction = action;
}

- (void) setOnCancelTarget:(id)target action:(SEL)action {
    _onCancelTarget = [NSObject releaseOld:_onCancelTarget retainNew:target];
    _onCancelAction = action;
}


@end

