//
//  Photo.m
//  LifeSpots
//
//  Created by Kwame Nelson on 10/28/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "Photo.h"

@implementation Photo

+ (Photo *)photoWithURL:(NSString *)s3URL
              TimeStamp:(NSDate *)timestamp
                  Likes:(NSInteger)likes
               Id:(NSInteger)photoId
                  Image:(UIImage *)image{
    
    Photo *photo = [[Photo alloc] init];
    NSString *s3URLString = [NSString stringWithFormat:@"%@%@",kS3_BASE_URL,s3URL];
    photo.s3Name = [NSURL URLWithString:s3URLString];
    photo.timeStamp = timestamp;
    photo.likes = likes;
    photo.image = image;
    photo.photoId = photoId;
    
    return photo;
}


+ (Photo *)photoWithId:(NSString *)photoId s3URL:(NSURL *)s3URL photoTaker:(NSString *)photoTakerId
{
   Photo *photo = [[Photo alloc] init];
   NSString *s3URLString = [NSString stringWithFormat:@"%@%@",kS3_BASE_URL,s3URL];
   photo.s3Name = [NSURL URLWithString:s3URLString];
   photo.photoId = [photoId integerValue];
   photo.photoTakerId = photoTakerId;
    
   return photo;
}

+ (void)showCommentsForPhotoWithID:(NSString *)photoId completion:(GeneralCompletion)completionBlock
{
    [[SubaAPIClient sharedInstance] GET:@"photo/comments" parameters:@{@"photoId": photoId} success:^(NSURLSessionDataTask *task, id responseObject) {
        completionBlock(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completionBlock(nil,error);
    }];
}


-(void)updateLikes:(NSString *)path IncrementFlag:(NSString *)updateFlag Params:(NSDictionary *)params completionBlock:(PhotoLikedCompletionBlock)block
{
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [requestParams addEntriesFromDictionary:@{@"updateFlag": updateFlag}];
    
    [[SubaAPIClient sharedInstance] POST:path parameters:requestParams success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *serverResponse = responseObject;
        block(serverResponse,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        block(nil,error);
    }];
    
}



@end
