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

#import "OBACoordinateBounds.h"
#import "OBATripQuery.h"


@interface OBAModelDAOUserPreferencesImpl : NSObject  {

}

- (NSArray*) readBookmarks;
- (void) writeBookmarks:(NSArray*)source;

- (NSArray*) readRecentPlaces;
- (void) writeRecentPlaces:(NSArray*)source;

- (NSArray*) readDroppedPins;
- (void) writeDroppedPins:(NSArray*)source;

- (NSArray*) readMostRecentStops;
- (void) writeMostRecentStops:(NSArray*)source;

- (OBACoordinateBounds*) readMostRecentMapBounds;
- (void) writeMostRecentMapBounds:(OBACoordinateBounds*)mostRecentMapBounds;

- (NSDictionary*) readStopPreferences;
- (void) writeStopPreferences:(NSDictionary*)stopPreferences;

- (CLLocation*) readMostRecentLocation;
- (void) writeMostRecentLocation:(CLLocation*)mostRecentLocation;

- (BOOL) hideFutureLocationWarnings;
- (void) setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings;

- (NSSet*) readVisistedSituationIds;
- (void) writeVisistedSituationIds:(NSSet*)situationIds;

- (OBATripQueryOptimizeForType) readDefaultTripQueryOptimizeForType;

@end
