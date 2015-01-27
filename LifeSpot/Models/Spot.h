//
//  Spot.h
//  LifeSpots
//
//  Created by Kwame Nelson on 11/2/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Privacy;
@class User;
@class Location;

typedef void (^SpotMembersLoadedCompletionBlock) (id results,NSError *error);
typedef void (^SpotInfoLoadedCompletion) (id results,NSError *error);
typedef void (^SpotInfoChangedCompletion) (id results,NSError *error);

@interface Spot : NSObject
@property (strong,nonatomic) NSString *name;
//@property (readwrite,nonatomic) NSString *description;
@property (strong,nonatomic) NSString *key;
@property (strong,nonatomic) Privacy *privacy;
@property (strong,nonatomic) Location *venue;
@property (strong,nonatomic) User *creator;


// Initializers
- (id)initWithName:(NSString *)name Key:(NSString *)key Privacy:(Privacy *)privacy User:(User *)user;
- (id)initWithName:(NSString *)name Privacy:(Privacy *)privacy User:(User *)user;
- (id)initWithName:(NSString *)name Key:(NSString *)key Privacy:(Privacy *)privacy Location:(Location *)location User:(User *)user;

// Selectors
+ (void)fetchMembersForSpot:(NSString *)spotId completion:(SpotMembersLoadedCompletionBlock)completion;
+ (void)fetchSpotInfo:(NSString *)spotId completion:(SpotInfoLoadedCompletion)completion;
+ (void)fetchSpotImagesUsingSpotId:(NSString *)spotId completion:(SpotInfoLoadedCompletion)completion;
+ (void)updateSpotInfo:(NSDictionary *)info completion:(SpotInfoChangedCompletion)completion;
@end
