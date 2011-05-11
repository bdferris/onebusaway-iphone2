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

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <SystemConfiguration/SystemConfiguration.h>

#import "OBAApplicationContext.h"
#import "OBANavigationTargetAware.h"
#import "OBALogger.h"

#import "OBAStopIconFactory.h"

#import "OBATripController.h"
#import "OBATripViewController.h"


#import "IASKAppSettingsViewController.h"


static NSString * kOBAHiddenPreferenceApplicationLastActiveTimestamp = @"OBAApplicationLastActiveTimestamp";
static NSString * kOBAHiddenPreferenceUserId = @"OBAApplicationUserId";
static NSString * kOBAHiddenPreferenceTabOrder = @"OBATabOrder";

static NSString * kOBADefaultApiServerName = @"soak-api.onebusaway.org";

static const double kMaxTimeSinceApplicationTerminationToRestoreState = 15 * 60;

static const NSUInteger kTagTripView = 0;
static const NSUInteger kTagBookmarkView = 1;
static const NSUInteger kTagContactUsView = 2;
static const NSUInteger kTagSettingsView = 3;


@interface OBAApplicationContext (Private)

- (void) saveState;

- (void) restoreState;
- (BOOL) shouldRestoreStateToDefault:(NSUserDefaults*)userDefaults;
- (void) restoreStateToDefault:(NSUserDefaults*)userDefaults;

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults;

- (NSString *)applicationDocumentsDirectory;

@end


@implementation OBAApplicationContext

@synthesize references = _references;
@synthesize locationManager = _locationManager;

@synthesize modelDao = _modelDao;
@synthesize modelService = _modelService;

@synthesize tripController = _tripController;
@synthesize currentTravelModeController = _currentTravelModeController;

@synthesize stopIconFactory = _stopIconFactory;

@synthesize window = _window;
@synthesize navController = _navController;

@synthesize active = _active;


- (id) init {
    
    self = [super init];
    
	if( self ) {
		
		_active = FALSE;
		
		_references = [[OBAReferencesV2 alloc] init];
		_modelDao = [[OBAModelDAO alloc] init];
		_locationManager = [[OBALocationManager alloc] initWithModelDao:_modelDao];		
		
		_modelService = [[OBAModelService alloc] init];
		_modelService.references = _references;
		_modelService.modelDao = _modelDao;
		
		OBAModelFactory * modelFactory = [[OBAModelFactory alloc] initWithReferences:_references];
		_modelService.modelFactory = modelFactory;
		[modelFactory release];
		
		_modelService.locationManager = _locationManager;
		
		_stopIconFactory = [[OBAStopIconFactory alloc] init];
        
        _tripController = [[OBATripController alloc] init];
        _tripController.locationManager = _locationManager;
        _tripController.modelService = _modelService;
		_tripController.modelDao = _modelDao;
        
        _currentTravelModeController = [[OBACurrentTravelModeController alloc] init];
        _currentTravelModeController.locationManager = _locationManager;
        _currentTravelModeController.modelService = _modelService;
            
		[self refreshSettings];
	}
	return self;
}

- (void) dealloc {
	[_modelDao release];
	[_modelService release];
	[_references release];
	
	[_locationManager release];
    
    [_tripController release];
    [_currentTravelModeController release];
	
	[_stopIconFactory release];
	
	[_window release];
	[_navController release];
    
	[super dealloc];
}

- (void) refreshSettings {
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
									
	NSString * apiServerName = [userDefaults objectForKey:@"oba_api_server"];
	if( apiServerName == nil || [apiServerName length] == 0 )
		apiServerName = kOBADefaultApiServerName;
	
	apiServerName = [NSString stringWithFormat:@"http://%@",apiServerName];
	
	NSString * userId = [self userIdFromDefaults:userDefaults];
	NSString * appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString * obaArgs = [NSString stringWithFormat:@"key=org.onebusaway.iphone&app_uid=%@&app_ver=%@",userId,appVersion];
	
	OBADataSourceConfig * obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:apiServerName args:obaArgs];	
	OBAJsonDataSource * obaJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:obaDataSourceConfig];
	_modelService.obaJsonDataSource = obaJsonDataSource;
	[obaJsonDataSource release];
	[obaDataSourceConfig release];
	
	OBADataSourceConfig * googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://maps.google.com" args:@"output=json&oe=utf-8&key=ABQIAAAA1R_R0bUhLYRwbQFpKHVowhRAXGY6QyK0faTs-0G7h9EE_iri4RRtKgRdKFvvraEP5PX_lP_RlqKkzA"];
	OBAJsonDataSource * googleMapsJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:googleMapsDataSourceConfig];
	_modelService.googleMapsJsonDataSource = googleMapsJsonDataSource;
	[googleMapsJsonDataSource release];
	[googleMapsDataSourceConfig release];
	
	[userDefaults setObject:appVersion forKey:@"oba_application_version"];
}

#pragma mark UIApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	
	/*
	_tabBarController.delegate = self;
	
	// Register a settings callback
	UINavigationController * navController = [_tabBarController.viewControllers objectAtIndex:kTagSettingsView];
	IASKAppSettingsViewController * vc = [navController.viewControllers objectAtIndex:0];
	vc.delegate = self;
     */
    
	UIView * rootView = [_navController view];
	[_window addSubview:rootView];
	[_window makeKeyAndVisible];
	
    [_locationManager addDelegate:_currentTravelModeController];
    
    [_locationManager startUpdatingLocation];
    
	[self restoreState];
    
    UIRemoteNotificationType type = (UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge);
    [application registerForRemoteNotificationTypes:type];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"Registered!");
    _modelService.deviceToken = deviceToken;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    OBALogWarningWithError(error, @"error registering for remote notifications");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	_active = TRUE;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	_active = FALSE;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	
    CLLocation * location = _locationManager.currentLocation;
	if( location )
		_modelDao.mostRecentLocation = location;
    
    NSArray * vcs = _navController.viewControllers;
    if( vcs && [vcs count] > 0 ) {
        OBATripViewController * vc = [vcs objectAtIndex:0];
        MKMapView * mapView = vc.mapView;
        OBACoordinateBounds * bounds = [[OBACoordinateBounds alloc] initWithRegion:mapView.region];
        _modelDao.mostRecentMapBounds = bounds;
        [bounds release];
    }
	
	[self saveState];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];

	/**
	 * If we've been in the background for a while (>15 mins), we restore
	 * the app to the user's preferred default state
	 */
	if( [self shouldRestoreStateToDefault:userDefaults] )
		[self restoreStateToDefault:userDefaults];
	
	
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self applicationDidEnterBackground:application]; // call for iOS < 4.0 devices
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Remote Notification: %@",[userInfo description]);
    NSString * alarmId = [userInfo objectForKey:@"alarmId"];
    if( alarmId ) {
        [_tripController handleAlarm:alarmId];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"Local Notification!");
}

#pragma mark UITabBarControllerDelegate Methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
	NSLog(@"title=%@",viewController.title);	
	return TRUE;
}

/**
 * We want to revert back to the root view of a selected controller when switching between tabs
 */
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	UINavigationController * nc = (UINavigationController *) viewController;
	/**
	 * Note that popToRootViewController didn't seem to work properly when called from the
	 * calling context of the UITabBarController.  So we punt it to the main thread.
	 */
	[nc performSelector:@selector(popToRootViewController) withObject:nil afterDelay:0];
}

/**
 * We want to save the tab order
 */
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
	
	NSUInteger count = tabBarController.viewControllers.count;
	NSMutableArray *tabOrderArray = [[NSMutableArray alloc] initWithCapacity:count];
	for (UIViewController *viewController in viewControllers) {		
		NSInteger tag = viewController.tabBarItem.tag;
		[tabOrderArray addObject:[NSNumber numberWithInteger:tag]];
	}
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:tabOrderArray forKey:kOBAHiddenPreferenceTabOrder];
	[userDefaults synchronize];
	
	[tabOrderArray release];
}

#pragma mark IASKSettingsDelegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
	[self refreshSettings];
}

@end


@implementation OBAApplicationContext (Private)

- (void) saveState {
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSDate * date = [NSDate date];
    NSData * dateData = [NSKeyedArchiver archivedDataWithRootObject:date];
	[userDefaults setObject:dateData forKey:kOBAHiddenPreferenceApplicationLastActiveTimestamp];
	
	[userDefaults synchronize];
}

- (void) restoreState {
    
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	if( [self shouldRestoreStateToDefault:userDefaults] ) {
		[self restoreStateToDefault:userDefaults];
		return;
	}
}

- (BOOL) shouldRestoreStateToDefault:(NSUserDefaults*)userDefaults {

	// We should only restore the application state if it's been less than x minutes
	// The idea is that, typically, if it's been more than x minutes, you've moved
	// on from the stop you were looking at, so we should just return to the users'
	// preferred home screen
	
	NSData * dateData = [userDefaults objectForKey:kOBAHiddenPreferenceApplicationLastActiveTimestamp];
	if( ! dateData ) 
		return TRUE;
	NSDate * date = [NSKeyedUnarchiver unarchiveObjectWithData:dateData];
	if( ! date || (-[date timeIntervalSinceNow]) > kMaxTimeSinceApplicationTerminationToRestoreState )
		return TRUE;
	
	return FALSE;
}

- (void) restoreStateToDefault:(NSUserDefaults*)userDefaults {
    
}

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults {
	
	NSString * userId = [userDefaults stringForKey:kOBAHiddenPreferenceUserId];
	
	if( ! userId) {
		CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
		if (theUUID) {
			userId = NSMakeCollectable(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
			CFRelease(theUUID);
			[userDefaults setObject:userId forKey:kOBAHiddenPreferenceUserId];
			[userDefaults synchronize];
		}
		else {
			userId = @"anonymous";
		}
	}
	
	return userId;
}


#pragma mark Application's documents directory

/**
 * Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	return basePath;
}

@end

