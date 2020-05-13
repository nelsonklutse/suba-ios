//
//  S3PhotoFetcher.h
//  LifeSpots
//
//  Created by Kwame Nelson on 11/14/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SDWebImage/UIImageView+WebCache.h>

@class DACircularProgressView;


#define kS3_BASE_URL @"https://s3.amazonaws.com/com.intruptiv.mypyx-photos/"
//#define kS3_BASE_URL @"https://s3.amazonaws.com/com.subaapp.photos/"

typedef void (^PhotoDownloadedCompletion) (id results,NSError *error);
typedef void (^PhotoDeletedCompletion) (id results,NSError *error);

@interface S3PhotoFetcher : NSObject
@property (strong,nonatomic) NSURL *s3BucketURL;


+ (id)s3FetcherWithBaseURL;
- (NSArray *)fetchPhotos:(NSString *)spotId;
-(void)downloadPhoto:(NSString *)photoURL completion:(PhotoDownloadedCompletion)completion;
-(void)downloadPhoto:(NSString *)photoURL to:(UIImageView *)imgView placeholderImage:(UIImage *)img completion:(PhotoDownloadedCompletion)completion;

-(void)downloadPhoto:(NSString *)photoURL
                  to:(UIImageView *)imgView
    placeholderImage:(UIImage *)img
        progressView:(DACircularProgressView *)progressView
      downloadOption:(SDWebImageOptions)option
          completion:(PhotoDownloadedCompletion)completion;

+ (void)deletePhotoFromStream:(NSDictionary *)photoInfo completion:(PhotoDeletedCompletion)completion;
@end
