//
//  Spot.m
//  LifeSpots
//
//  Created by Kwame Nelson on 11/2/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "Spot.h"
#import "Privacy.h"

@interface Spot()

@end


@implementation Spot

-(id)initWithName:(NSString *)name Privacy:(Privacy *)privacy User:(User *)user{
    
    if (self = [super init]) {
        self.name = name;
        self.privacy = privacy;
        self.creator = user;
    }
    return self;
}

-(id)initWithName:(NSString *)name Key:(NSString *)key Privacy:(Privacy *)privacy User:(User *)user
{
    self = [self initWithName:name Privacy:privacy User:user];
    if (self){
        self.key = key;
    }
    return self;
}



-(id)initWithName:(NSString *)name Key:(NSString *)key Privacy:(Privacy *)privacy Location:(Location *)location User:(User *)user
{
    self = [self initWithName:name Key:key Privacy:privacy User:user];
    if (self) {
        self.venue = location;
    }
    
    return self;
}


+ (void)fetchMembersForSpot:(NSString *)spotId completion:(SpotMembersLoadedCompletionBlock)completion
{
    [[SubaAPIClient sharedInstance] GET:@"spot/members/all"
                                  parameters:@{@"spotId": spotId}
                                     success:^(NSURLSessionDataTask *task, id responseObject) {
        NSArray *serverPesponse = (NSArray *)responseObject[@"members"];
        completion(serverPesponse,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error); 
    }];
}

+(void)fetchSpotInfo:(NSString *)spotId completion:(SpotInfoLoadedCompletion)completion
{
    //DLog(@"SpotId - %@\nUserId - %@",spotId,userId);
    [[SubaAPIClient sharedInstance] GET:@"spot/info"
                                  parameters:@{@"spotId":spotId}
                                     success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}



+(void)fetchSpotImagesUsingSpotId:(NSString *)spotId completion:(SpotInfoLoadedCompletion)completion
{
    NSDictionary *params = nil;
    if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
         params = @{@"spotId": spotId,@"tempUserKey":kSUBA_USER_TEMPORARY_ID};
    }else{
       params = @{@"spotId": spotId,@"userId":[AppHelper userID]};
    } 
    DLog(@"Params - %@",params); 
    [[SubaAPIClient sharedInstance] GET:@"spot/photos/all" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}

+(void)updateSpotInfo:(NSDictionary *)info completion:(SpotInfoChangedCompletion)completion
{
    [[SubaAPIClient sharedInstance] POST:@"spot/info/edit" parameters:info success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        completion(nil,error);
    }];
}

@end
