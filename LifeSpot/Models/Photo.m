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



-(void)updateLikes:(NSString *)path IncrementFlag:(NSString *)updateFlag Params:(NSDictionary *)params completionBlock:(PhotoLikedCompletionBlock)block
{
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [requestParams addEntriesFromDictionary:@{@"updateFlag": updateFlag}];
    
    [[LifespotsAPIClient sharedInstance] POST:path parameters:requestParams success:^(NSURLSessionDataTask *task, id responseObject) {
        NSDictionary *serverResponse = responseObject;
        block(serverResponse,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        block(nil,error);
    }];
    
    
}
@end
