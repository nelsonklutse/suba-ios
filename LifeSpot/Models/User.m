//
//  User.m
//  LifeSpots
//
//  Created by Kwame Nelson on 10/28/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "User.h"
#import "SubaAPIClient.h"
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

+ (User *)userWithID:(NSString *)userID
{
    User *user = [[User alloc] init];
    user.userID = userID;
    
    return user;
}

+ (User *)currentlyActiveUser{
    User *user = [[User alloc] init];
    user.userID = [[NSUserDefaults standardUserDefaults] valueForKey:API_TOKEN];
    user.photos = [NSMutableDictionary dictionary];
    user.spots = [NSMutableArray array];
    
    return user;
}

+ (User *)userWithId:(NSString *)userId userName:(NSString *)username profilePhotoURL:(NSURL *)url
{
    User *user = [[User alloc] init];
    user.userID = userId;
    user.userName = username;
    user.profilePhotoURL = url;
    
    return user;
  
}

-(void)savePreferences:(NSDictionary *)preferences
{
    
}


#pragma mark -API calls
// Make it block based later
- (void)loadPersonalSpotsWithCompletion:(PersonalSpotsLoadedCompletionBlock)completion{
    
    [[SubaAPIClient sharedInstance] GET:@"user/spots/personal" parameters:@{@"userId":self.userID} success:^(NSURLSessionDataTask *task, id responseObject){
        
        //DLog(@"Response object as recieved from the server - %@\nNumber of JSON objects - %lu",responseObject,(unsigned long)[responseObject[@"spots"] count]);
        
            //NSArray *streams = responseObject[@"spots"];
        
            completion(responseObject,nil);
        
        //DLog(@"Number of user albums - %lu\nThe streams - %@",(unsigned long)[streams count],streams);
        //[[NSNotificationCenter defaultCenter] postNotificationName:kUserDidLoadPersonalSpotsNotification object:albums userInfo:@{@"albums": @"loaded"}];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


-(void)fetchCreatedSpotsCompletion:(NSString *)userId completion:(CreatedSpotsLoadedCompletionBlock)completion
{
    DLog(@"UserId - %@",userId); 
    [[SubaAPIClient sharedInstance] GET:@"user/spots/created" parameters:@{@"userId": userId} success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}




-(void)createSpot:(Spot *)spot completion:(SpotCreatedCompletionBlock)completion{
    
    NSMutableDictionary *requestparams = nil;
    NSDictionary *locationDetails = nil;
    //DLog(@");
    if (spot.venue != nil) {
        if (spot.venue.city == nil && spot.venue.country != nil){
            
            locationDetails = @{
                                @"latitude": spot.venue.latitude,
                                @"longitude" : spot.venue.longitude,
                                @"albumVenue" : spot.venue.placeName,
                                @"country" : spot.venue.country
                                };
        }else if (spot.venue.country == nil && spot.venue.city != nil){
            
            locationDetails = @{
                                @"latitude": spot.venue.latitude,
                                @"longitude" : spot.venue.longitude,
                                @"albumVenue" : spot.venue.placeName,
                                @"city" : spot.venue.city
                                };
        }else if(!spot.venue.city && !spot.venue.country){
            
            locationDetails = @{
                                @"latitude": spot.venue.latitude,
                                @"longitude" : spot.venue.longitude,
                                @"albumVenue" : spot.venue.placeName
                                };
        }else{
            
            locationDetails = @{
                                @"latitude": spot.venue.latitude,
                                @"longitude" : spot.venue.longitude,
                                @"albumVenue" : spot.venue.placeName,
                                @"city" : spot.venue.city,
                                @"country" : spot.venue.country
                                };
        }
        
        
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
    
    [[SubaAPIClient sharedInstance] POST:@"spot/create" parameters:requestparams success:^(NSURLSessionDataTask *task, id responseObject){
        
        if ([responseObject[STATUS] isEqualToString:ALRIGHT]){
            [AppHelper updateNumberOfAlbums:1];
            completion(responseObject,nil); 
        }
        
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


/*- (void)addDoodleToPhoto:(NSDictionary *)info completion:(GeneralCompletion)completion
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@",[SubaAPIClient subaAPIBaseURL]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    //NSURL *filePath = [NSURL fileURLWithPath:@"file://path/to/image.png"];
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithRequest:request fromData:info[@"fileData"] progress:(NSProgress *__autoreleasing *)progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            completion(nil,error);
        } else {
            completion(responseObject,nil);
        }
    }];
    
    [uploadTask resume];
}*/


+ (void)updateFullName:(NSDictionary *)userInfo completion:(UserProfileInfoUpdatedCompletion)completion
{
    [[SubaAPIClient sharedInstance] POST:@"user/account/update/fullName" parameters:userInfo success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


- (void)updateProfileInfo:(NSDictionary *)userInfo completion:(UserProfileInfoUpdatedCompletion)completion
{
    //DLog(@"User info - %@",userInfo[@"form-encoded"]);
    
    if([userInfo[@"picName"] isEqualToString:@"UNCHANGED"]){
        [[SubaAPIClient sharedInstance] POST:@"user/account/update" parameters:userInfo[@"form-encoded"] constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
    } success:^(NSURLSessionDataTask *task, id responseObject){
            completion(responseObject,nil);
        } failure:^(NSURLSessionDataTask *task, NSError *error){
            completion(nil,error);
        }];
        
    }else{
    [[SubaAPIClient sharedInstance] POST:@"user/account/update" parameters:userInfo[@"form-encoded"] constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        [formData appendPartWithFileData:userInfo[@"imageData"] name:@"profilePicture" fileName:userInfo[@"picName"] mimeType:@"image/jpeg"];
        
    } success:^(NSURLSessionDataTask *task, id responseObject){
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        completion(nil,error);
    }];
  }
}



+(void)fetchUserProfileInfoCompletion:(NSString *)userId completion:(ProfileInfoLoadedCompletionBlock)completion
{
    [[SubaAPIClient sharedInstance] GET:@"user/info"
                                  parameters:@{@"userId": userId}
                                     success:^(NSURLSessionDataTask *task, id responseObject) {
                                         
        completion(responseObject,nil);
                                         
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        completion(nil,error);
    }];
}

- (void)fetchFavoriteLocationsCompletions:(FavoriteLocationsCompletionBlock)completion
{
    [[SubaAPIClient sharedInstance] GET:@"user/locations/watching" parameters:@{@"userId":self.userID} success:^(NSURLSessionDataTask *task, id responseObject) {
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
    
    [[SubaAPIClient sharedInstance] POST:@"user/location/watch" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


-(void)removeLocationFromWatching:(NSString *)locationName Completion:(AddLocationToWatchingCompletionBlock)completion
{
    NSDictionary *params = @{@"place": locationName,
                             @"userId" : self.userID};
    
    [[SubaAPIClient sharedInstance] POST:@"user/location/unwatch" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


-(void)loadFriendsSpotsWithCompletion:(FriendSpotsCompletionBlock)completion
{
    [[SubaAPIClient sharedInstance] GET:@"user/friendspots" parameters:@{@"userId": self.userID} success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}

-(void)joinSpotCompletionCode:(NSString *)code completion:(SpotJoinedCompletionBlock)completion
{    [[SubaAPIClient sharedInstance] GET:@"spot/join"
                                  parameters:@{ @"userId":self.userID, @"albumCode":code}
                                     success:^(NSURLSessionDataTask *task, id responseObject){
                                         DLog(@"Back from server - %@",responseObject);
            
            //[AppHelper updateNumberOfAlbums:1];
            completion(responseObject,nil);

    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        //DLog(@"Back from server - %@",error.debugDescription);
        completion(nil,error);
    }];

}


-(void)joinSpot:(NSString *)spotId completion:(SpotJoinedCompletionBlock)completion

{
    [[SubaAPIClient sharedInstance] GET:@"spot/join"
                                   parameters:@{ @"userId":self.userID, @"spotId": spotId}
                                      success:^(NSURLSessionDataTask *task, id responseObject){
                                          //DLog(@"Joined user to stream");
                                          //DLog(@"Back from server - %@",responseObject);
                                          
                                          [AppHelper updateNumberOfAlbums:1];
                                          completion(responseObject,nil);
                                          
                                      } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                          completion(nil,error);
                            }];
    
}


-(void)leaveSpot:(NSString *)spotId completion:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance] POST:@"spot/leave"
                                   parameters:@{ @"userId":self.userID, @"albumId":spotId}
                                      success:^(NSURLSessionDataTask *task, id responseObject){
                                          
                                          if ([responseObject[STATUS] isEqualToString:ALRIGHT]){
                                              
                                              [AppHelper updateNumberOfAlbums:(-1)];
                                              
                                              completion(responseObject,nil);
                                          }
                                          
                                      } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                          completion(nil,error);
                                          
                                      }];
    
}

-(void)deleteStream:(NSString *)spotId completion:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance] POST:@"stream/delete"
                              parameters:@{ @"userId":self.userID, @"streamId":spotId}
                                 success:^(NSURLSessionDataTask *task, id responseObject) {
                                     completion(responseObject,nil);
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
    
    [[SubaAPIClient sharedInstance] POST:@"user/follow" parameters:params success:^(NSURLSessionDataTask *task, id responseObject){
        
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        
        completion(nil,error);
    }];
}

-(void)changePassOld:(NSString *)oldPass newPass:(NSString *)newPass completion:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance]
                        POST:@"user/account/changepass"
     
     parameters:@{@"userId": self.userID,@"oldPassword": oldPass ,@"newPassword" : newPass}
                        success:^(NSURLSessionDataTask *task, id responseObject) {
                            completion(responseObject,nil);
                        } failure:^(NSURLSessionDataTask *task, NSError *error) {
                            completion(nil,error);
           }];
}


-(void)isUserFollowing:(NSString *)otherUserId completion:(IsUserFollowing)completion
{
    [[SubaAPIClient sharedInstance] GET:@"user/follows" parameters:@{@"userId": self.userID, @"otherUserId" : otherUserId} success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


-(void)likePhoto:(NSDictionary *)params completion:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance] POST:@"picture/like" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error); 
    }];
}


-(void)inviteUsersToStreamViaEmail:(NSDictionary *)params completion:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance] POST:@"user/stream/invite" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error); 
    }];
}

- (void)fetchGlobalStreams:(NSDictionary *)params completion:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance] GET:@"streams/global" parameters:params success:^(NSURLSessionDataTask *task, id responseObject){ 
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}

+ (void)allUsers:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance] GET:@"users/all" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


+ (void)reportPhoto:(NSDictionary *)params completion:(GeneralCompletion)completion
{
    //DLog(@"Params - %@",params);
    [[SubaAPIClient sharedInstance] POST:@"user/photo/report"
                                   parameters:params
                                      success:^(NSURLSessionDataTask *task, id responseObject) {
                                          completion(responseObject,nil);
                                      } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                          completion(nil,error);
                                      }];
}



- (void)commentOnPhoto:(NSDictionary *)params completion:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance] POST:@"photo/comment" parameters:params success:^(NSURLSessionDataTask *task, id responseObject){
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}



+ (void)commentsForPhoto:(NSDictionary *)params completion:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance] POST:@"photo/comments" parameters:params success:^(NSURLSessionDataTask *task,id responseObject){
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}



+ (void)enterInviteCodeToJoinStream:(NSDictionary *)params completion:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance] GET:@"stream/join/secret" parameters:params success:^(NSURLSessionDataTask *task, id responseObject){
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}


+(void)createGuestAccount:(GeneralCompletion)completion
{
    [[SubaAPIClient sharedInstance] POST:@"account/create/guest" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}

+(void)updateUserStat:(NSString *)stat completion:(GeneralCompletion)completionBlock
{
    NSString *userID = [AppHelper userID];
    
    [[SubaAPIClient sharedInstance] POST:@"user/stats/update"
                              parameters:@{@"userId": userID, stat: @"1"}
                                 success:^(NSURLSessionDataTask *task, id responseObject) {
        completionBlock(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completionBlock(nil,error);
    }];
}



+(void)resetPassword:(NSString *)email completion:(GeneralCompletion)completionHandler
{
    [[SubaAPIClient sharedInstance] POST:@"user/account/reset/email" parameters:@{@"email" : email} success:^(NSURLSessionDataTask *task, id responseObject){
        DLog(@"response: %@",responseObject);
        completionHandler(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"response: %@",error);
        completionHandler(nil,error);
    }];
}




@end
