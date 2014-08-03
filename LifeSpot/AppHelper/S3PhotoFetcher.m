//
//  S3PhotoFetcher.m
//  LifeSpots
//
//  Created by Kwame Nelson on 11/14/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "S3PhotoFetcher.h"
#import "DACircularProgressView.h"

@implementation S3PhotoFetcher


+(id)s3FetcherWithBaseURL
{
    S3PhotoFetcher *aws3Fetcher = [[S3PhotoFetcher alloc] init];
    aws3Fetcher.s3BucketURL = [NSURL URLWithString:kS3_BASE_URL];
    return aws3Fetcher;
}

// This needs some work
-(NSArray *)fetchPhotos:(NSString *)spotId
{
    static NSArray *__photos;
    
    [[SubaAPIClient sharedInstance] GET:@"album/photos/all" parameters:@{@"spotId": spotId} success:^(NSURLSessionDataTask *task, id responseObject) {
        __photos = responseObject[@"spotPhotos"];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Error - %@",error);
    }];
    
    return __photos;
}


-(void)downloadPhoto:(NSString *)photoURL to:(UIImageView *)imgView placeholderImage:(UIImage *)img completion:(PhotoDownloadedCompletion)completion
{
    //__weak UIImageView *targetImgView = imgView;
    dispatch_queue_t downloadPhotoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(downloadPhotoQueue, ^{
        __weak UIImageView *mainImageView = imgView;
        NSURL *photoSrc = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",self.s3BucketURL,photoURL]];
        //NSURLRequest *request = [NSURLRequest requestWithURL:photoSrc];
        //NSLog(@"Making image request from - %@",[photoSrc description]);
        dispatch_async(dispatch_get_main_queue(),^{
                [imgView setImageWithURL:photoSrc placeholderImage:img options:SDWebImageProgressiveDownload completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                if (!error) {
                    mainImageView.image = image;
                    completion(image,nil);
                }else{
                   completion(nil,error);
                }
            }];
            
            
            
        });
        
    });
}



-(void)downloadPhoto:(NSString *)photoURL completion:(PhotoDownloadedCompletion)completion
{
    //DLog(@"Downloading photo");
    dispatch_queue_t downloadPhotoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(downloadPhotoQueue, ^{
        //__weak UIImageView *mainImageView = imgView;
        NSURL *photoSrc = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",self.s3BucketURL,photoURL]];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:photoSrc];
        
        dispatch_async(dispatch_get_main_queue(),^{
            
           // DLog(@"Photo source - %@",photoSrc);
            
            AFHTTPRequestOperation *postOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
            postOperation.responseSerializer = [AFImageResponseSerializer serializer];
            [postOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, UIImage *responseObject) {
              //  DLog(@"Image Request Operation: %@", operation.request);
                //_imageView.image = responseObject;
                completion(responseObject,nil);
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DLog(@"Image error: %@", error);
                completion(nil,error);
            }];

            [postOperation start];
        });
        
    });
}


-(void)downloadPhoto:(NSString *)photoURL to:(UIImageView *)imgView placeholderImage:(UIImage *)img progressView:(DACircularProgressView *)progressView downloadOption:(SDWebImageOptions)option completion:(PhotoDownloadedCompletion)completion
{
    //__weak UIImageView *targetImgView = imgView;
    __weak DACircularProgressView *pView = progressView;
    //__weak SDWebImageOptions imageDownloadOption = option;
    dispatch_queue_t downloadPhotoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(downloadPhotoQueue, ^{
        __weak UIImageView *mainImageView = imgView;
        NSURL *photoSrc = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",self.s3BucketURL,photoURL]];
        
        dispatch_async(dispatch_get_main_queue(),^{
         
     [imgView setImageWithURL:photoSrc placeholderImage:img options:option progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                CGFloat progress =  (float)receivedSize/expectedSize;  
                pView.progress = progress;
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                if (!error) {
                    mainImageView.image = image;
                    //DLog(@"Image size downlaoded - %@",NSStringFromCGSize(image.size));
                    completion(image,nil);
                }else{
                    completion(nil,error);
                }

            }];
    });
        
 });
 
}


+(void)deletePhotoFromStream:(NSDictionary *)photoInfo completion:(PhotoDeletedCompletion)completion
{
    [[SubaAPIClient sharedInstance] POST:@"photo/delete"
                              parameters:@{@"userId" : [AppHelper userID],@"photoId" : photoInfo[@"id"]} success:^(NSURLSessionDataTask *task, id responseObject) {
        completion(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil,error);
    }];
}

@end
