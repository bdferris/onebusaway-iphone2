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
#import "OBATripController.h"


@interface OBATripViewController : UIViewController <MKMapViewDelegate,OBATripControllerDelegate> {

}

@property (nonatomic,retain) IBOutlet OBAApplicationContext * appContext;
@property (nonatomic,retain) OBATripController * tripController;

@property (nonatomic,retain) IBOutlet MKMapView * mapView;
@property (nonatomic,retain) IBOutlet UIBarButtonItem * currentLocationButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem * editButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem * leftButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem * rightButton;

-(IBAction) onCrossHairsButton:(id)sender;
-(IBAction) onEditButton:(id)sender;
-(IBAction) onLeftButton:(id)sender;
-(IBAction) onRightButton:(id)sender;
-(IBAction) onBookmakrButton:(id)sender;

@end
