//
//  User.m
//  LifeSpots
//
//  Created by Kwame Nelson on 10/28/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "User.h"
#import "LifespotsAPIClient.h"
#import "Spot.h"
#import "Privacy.h"
#import "Location.h"
#import "LSPushProviderAPIClient.h"


@interface User()

@property (copy,nonatomic) NSString *userID;
@property (copy,nonatomic) NSString *firstname;
@property (copy,nonatomic) NSString *lastName;
@property (copy,nonatomic) NSString *userName;
@property (copy,nonatomic) NSString *email;
@property (copy,nonatomic) NSString *password;
@property (strong,nonatomic) NSMutableDictionary *photos;    //  of photos
@property (strong,nonatomic) NSMutableArray *spots;  // of spots
@property (strong,nonatomic) NSURL *profilePhotoURL;

@end

@implementation User

- (id)initWithAttributes:(NSDictionary *)attributes{
    
    self.userID = attributes[@"token"];
    self.firstname = attributes[@"firstName"];
    self.lastName = attributes[@"lastName"];
    self.userName = attributes[@"userName"];
    self.email = attributes[@"email"];
    
    return self;
}

- (id)initWithUserName:(NSString *)userName Email:(NSString *)email AndPassword:(NSString *)password{
    self = [super init];
    if (!self) {
        return nil;
    }
    self.userName = userName;
    self.email = email;
    self.password = password;
    
    return self;
}

+(User *)currentlyActiveUser{
    User *user = [[User alloc] init];
    user.userID = [[NSUserDefaults standardUserDefaults] valueForKey:API_TOKEN];
    user.photos = [NSMutableDictionary dictionary];
    user.spots = [NSMutableArray array];
    return user;
}

-(void)savePreferences:(NSDictionary *)preferences{
    
}


#pragma mark -API calls
// Make it block based later
- (void)loadPersonalSpotsWithCompletion:(PersonalSpotsLoadedCompletionBlock)completion{
    
    [[LifespotsAPIClient sharedInstance] GET:@"user/spots/personal" parameters:@{@"userId":self.userID} success:^(NSURLSessionDataTask *task, id responseObject){
        NSArray *albums = (NSArray *)responseObject;
        completion(albums,nil);
        
        //[[NSNotificationCenter defaultCenter] postNotificationName:kUserDidLoadPersonalSpotsNotification object:albums userInfo:@{@"albums": @"loaded"}];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


-(void)fetchCreatedSpotsCompletion:(NSString *)userId completion:(CreatedSpotsLoadedCompletionBlock)completion
{
    [[LifespotsAPIClient sharedInstance] GET:@"user/spots/created" parameters:@{@"userId": userId} success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}




-(void)createSpot:(Spot *)spot completion:(SpotCreatedCompletionBlock)completion{
    
    NSMutableDictionary *requestparams = nil;
    NSDictionary *locationDetails = nil;
    
    if (spot.venue != nil) {
        locationDetails = @{
                            @"latitude": spot.venue.latitude,
                            @"longitude" : spot.venue.longitude,
                            @"albumVenue" : spot.venue.placeName
                            };
    }else{
        locationDetails = @{
                            @"latitude": @"0",
                            @"longitude" : @"0",
                            @"albumVenue" : @"NONE"
                            };
    }
    NSDictionary *albumDetailsParams = @{
                          @"userId": spot.creator.userID,
                          @"albumName" : spot.name,
                          @"albumPass" : spot.key,
                          @"viewControl" : spot.privacy.viewPrivacy,
                          @"addControl" : spot.privacy.addPrivacy
                          
                     };
    
    
    requestparams = [NSMutableDictionary dictionaryWithDictionary:albumDetailsParams];
    [requestparams addEntriesFromDictionary:locationDetails];
    
    [[LifespotsAPIClient sharedInstance] POST:@"spot/create" parameters:requestparams success:^(NSURLSessionDataTask *task, id responseObject){
        
        if ([responseObject[STATUS] isEqualToString:ALRIGHT]){
            [AppHelper updateNumberOfAlbums:1];
            completion(responseObject,nil);
        }
        
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


- (void)updateProfileInfo:(NSDictionary *)userInfo completion:(UserProfileInfoUpdatedCompletion)completion
{
    [[LifespotsAPIClient sharedInstance] POST:@"user/account/update" parameters:userInfo[@"form-encoded"] constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        [formData appendPartWithFileData:userInfo[@"imageData"] name:@"profilePicture" fileName:userInfo[@"picName"] mimeType:@"image/jpeg"];
        
    } success:^(NSURLSessionDataTask *task, id responseObject){
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        completion(nil,error);
    }];
}



+(void)fetchUserProfileInfoCompletion:(NSString *)userId completion:(ProfileInfoLoadedCompletionBlock)completion
{
    [[LifespotsAPIClient sharedInstance] GET:@"user/info"
                                  parameters:@{@"userId": userId}
                                     success:^(NSURLSessionDataTask *task, id responseObject) {
                                         
        completion(responseObject,nil);
                                         
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        completion(nil,error);
    }];
}

- (void)fetchFavoriteLocationsCompletions:(FavoriteLocationsCompletionBlock)completion
{
    [[LifespotsAPIClient sharedInstance] GET:@"user/locations/watching" parameters:@{@"userId":self.userID} success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


- (void)addLocationToWatching:(Location *)location Completion:(AddLocationToWatchingCompletionBlock)completion
{
    NSDictionary *params = @{@"place": location.placeName,
                             @"latitude" : location.latitude,
                             @"longitude": location.longitude,
                             @"userId" : self.userID};
    
    [[LifespotsAPIClient sharedInstance] POST:@"user/location/watch" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


-(void)removeLocationFromWatching:(NSString *)locationName Completion:(AddLocationToWatchingCompletionBlock)completion
{
    NSDictionary *params = @{@"place": locationName,
                             @"userId" : self.userID};
    
    [[LifespotsAPIClient sharedInstance] POST:@"user/location/unwatch" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


-(void)loadFriendsSpotsWithCompletion:(FriendSpotsCompletionBlock)completion
{
    [[LifespotsAPIClient sharedInstance] GET:@"user/friendspots" parameters:@{@"userId": self.userID} success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}

-(void)joinSpotCompletionCode:(NSString *)code completion:(SpotJoinedCompletionBlock)completion
{    [[LifespotsAPIClient sharedInstance] GET:@"spot/join"
                                  parameters:@{ @"userId":self.userID, @"albumCode":code}
                                     success:^(NSURLSessionDataTask *task, id responseObject){
                                         
        if ([responseObject[STATUS] isEqualToString:ALRIGHT]){
            
            [AppHelper updateNumberOfAlbums:1];
            completion(responseObject,nil);
            
            //[self performSegueWithIdentifier:@"spotcelltoalbum" sender:responseObject];
        }

    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);

    }];

}


-(void)followUser:(NSString *)beingFollowed completion:(FollowUserCompletion)completion
{
    NSDictionary *params = @{@"beingFollowedId" : beingFollowed, @"followerId" : self.userID};
    NSDictionary *followParams = @{@"beingFollowedId" : beingFollowed, @"followerId" : self.userID,@"followerName": [AppHelper userName]};
    [[LSPushProviderAPIClient sharedInstance] POST:@"newfollower" parameters:followParams success:^(NSURLSessionDataTask *task, id responseObject) {
        // We need to do analytics here
        NSLog(@"Successfully followed");
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        // We need to do analytics here
        NSLog(@"Error -  %@",error);
    }];
    
    [[LifespotsAPIClient sharedInstance] POST:@"user/follow" parameters:params success:^(NSURLSessionDataTask *task, id responseObject){
        
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        
        completion(nil,error);
    }];
}

-(void)changePass:(NSString *)pass
{
    [[LifespotsAPIClient sharedInstance]
                        POST:@"user/account/p"
     
     parameters:@{@"userId" : self.userID,@"pass": pass}
                        success:nil
                        failure:nil];
}


-(void)isUserFollowing:(NSString *)otherUserId completion:(IsUserFollowing)completion
{
    [[LifespotsAPIClient sharedInstance] GET:@"user/follows" parameters:@{@"userId": self.userID, @"otherUserId" : otherUserId} success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


+(void)allUsers:(GeneralCompletion)completion
{
    [[LifespotsAPIClient sharedInstance] GET:@"users/all" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}
@end