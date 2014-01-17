//
//  Location.h
//  LifeSpots
//
//  Created by Kwame Nelson on 11/2/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^NearbySpotsLoadedCompletionBlock) (id results,NSError *error);
typedef void (^MatchingLocationsCompletionBlock) (id results,NSError *error);
typedef void (^ExactFoursquareLocationFoundCompletionBlock) (id results,NSError *error);

@interface Location : NSObject

@property (strong,nonatomic) NSString *latitude;
@property (strong,nonatomic) NSString *longitude;
@property (strong,nonatomic) NSString *placeName;
@property (strong,nonatomic) NSString *address;
@property (strong,nonatomic) NSString *city;
@property (strong,nonatomic) NSString *country;

- (id)initWithLat:(NSString *)latitude Lng:(NSString *)longitude PrettyName:(NSString *)place;
- (id)initWithLat:(NSString *)latitude Lng:(NSString *)longitude;
- (id)initWithLat:(NSString *)latitude
              Lng:(NSString *)longitude
        PlaceName:(NSString *)place
          Address:(NSString *)address
             City:(NSString *)city
          Country:(NSString *)country;

+ (void)searchFourquareWithSearchTerm:(NSString *)searchText
                      completionBlock:(MatchingLocationsCompletionBlock)completion;

+ (void)fetchNearbySpots:(NSDictionary *)location
         completionBlock:(NearbySpotsLoadedCompletionBlock)completion;

- (void)showBestMatchingFoursquareVenueCompletion:(ExactFoursquareLocationFoundCompletionBlock)completion;

-(NSString *)description;

@end
