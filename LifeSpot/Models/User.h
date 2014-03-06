//
//  User.h
//  LifeSpots
//
//  Created by Kwame Nelson on 10/28/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Spot;
@class Location;

typedef void (^CreatedSpotsLoadedCompletionBlock) (id results,NSError *error);
typedef void (^ProfileInfoLoadedCompletionBlock) (id results,NSError *error);
typedef void (^FavoriteLocationsCompletionBlock) (id results,NSError *error);
typedef void (^PersonalSpotsLoadedCompletionBlock) (id results, NSError *error);
typedef void (^AddLocationToWatchingCompletionBlock) (id results,NSError *error);
typedef void (^SpotCreatedCompletionBlock) (id results,NSError *error);
typedef void (^FriendSpotsCompletionBlock) (id results,NSError *error);
typedef void (^SpotJoinedCompletionBlock) (id results,NSError *error);
typedef void (^FollowUserCompletion) (id results,NSError *error);
typedef void (^UserProfileInfoUpdatedCompletion) (id results,NSError *error);
typedef void (^LeaveSpotCompletion) (id results,NSError *error);
typedef void (^IsUserFollowing) (id results,NSError *error);
typedef void (^GeneralCompletion) (id results,NSError *error);



@interface User : NSObject

@property (readonly,nonatomic,copy) NSString *userID;
@property (readonly,nonatomic,copy) NSString *userName;
@property (readonly,nonatomic,copy) NSString *email;
@property (readonly,nonatomic,copy) NSString *password;
@property (readonly,nonatomic,copy) NSString *firstname;
@property (readonly,nonatomic,copy) NSString *lastName;
@property (readonly,nonatomic) NSURL *profilePhotoURL;

+ (User *)currentlyActiveUser;
- (id)initWithAttributes:(NSDictionary *)attributes;
- (id)initWithUserName:(NSString *)userName Email:(NSString *)email AndPassword:(NSString *)password;

- (void)savePreferences:(NSDictionary *)preferences;
- (void)createSpot:(Spot *)spot completion:(SpotCreatedCompletionBlock)completion;
- (void)loadPersonalSpotsWithCompletion:(PersonalSpotsLoadedCompletionBlock)completion;
- (void)updateProfileInfo:(NSDictionary *)userInfo completion:(UserProfileInfoUpdatedCompletion)completion;
- (void)fetchCreatedSpotsCompletion:(NSString *)userId completion:(CreatedSpotsLoadedCompletionBlock)completion;
+ (void)fetchUserProfileInfoCompletion:(NSString *)userId completion:(ProfileInfoLoadedCompletionBlock)completion;
- (void)fetchFavoriteLocationsCompletions:(FavoriteLocationsCompletionBlock)completion;
- (void)addLocationToWatching:(Location *)location Completion:(AddLocationToWatchingCompletionBlock)completion;
- (void)removeLocationFromWatching:(NSString *)locationName Completion:(AddLocationToWatchingCompletionBlock)completion;
- (void)loadFriendsSpotsWithCompletion:(FriendSpotsCompletionBlock)completion;
- (void)joinSpotCompletionCode:(NSString *)code completion:(SpotJoinedCompletionBlock)completion;
- (void)joinSpot:(NSString *)spotId completion:(SpotJoinedCompletionBlock)completion;
- (void)leaveSpot:(NSString *)spotId completion:(GeneralCompletion)completion;
- (void)followUser:(NSString *)beingFollowed completion:(FollowUserCompletion)completion;
- (void)changePassOld:(NSString *)oldPass newPass:(NSString *)newPass completion:(GeneralCompletion)completion;
- (void)isUserFollowing:(NSString *)otherUserId completion:(IsUserFollowing)completion;
- (void)likePhoto:(NSDictionary *)params completion:(GeneralCompletion)completion;
                                                
+ (void)allUsers:(GeneralCompletion)completion;
+ (void)reportPhoto:(NSDictionary *)params completion:(GeneralCompletion)completion;

+ (void)saveInviteeNumber:(NSDictionary *)params completion:(GeneralCompletion)completion;

@end
