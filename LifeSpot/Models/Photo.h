//
//  Photo.h
//  LifeSpots
//
//  Created by Kwame Nelson on 10/28/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Photo : NSObject

typedef void (^PhotoLikedCompletionBlock) (NSDictionary *results,NSError *error);

@property NSUInteger photoId;
@property (strong,nonatomic) UIImage *image;
@property (strong,nonatomic) NSURL *s3Name;
@property (strong,nonatomic) NSDate   *timeStamp;
@property NSInteger likes;

+ (Photo *)photoWithURL:(NSString *)s3URL
              TimeStamp:(NSDate *)timestamp
                  Likes:(NSInteger)likes
               Id:(NSInteger)photoId
                  Image:(UIImage *)image;

- (void)updateLikes:(NSString *)path IncrementFlag:(NSString *)updateFlag
             Params:(NSDictionary *)params
    completionBlock:(PhotoLikedCompletionBlock)block;

@end
