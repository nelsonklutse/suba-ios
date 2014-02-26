//
//  FacebookAPIClient.m
//  LifeSpot
//
//  Created by Kwame Nelson on 2/17/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.



#import "FacebookAPIClient.h"

@implementation FacebookAPIClient

static NSString * const FacebookAPIBaseURLString = @"https://graph.facebook.com/";

+ (instancetype)sharedInstance
{
    static FacebookAPIClient *__sharedInstance;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        __sharedInstance = [[FacebookAPIClient alloc]
                            initWithBaseURL:[NSURL URLWithString:FacebookAPIBaseURLString]
                            sessionConfiguration:configuration];
    });
    
    //[__sharedInstance.requestSerializer setValue:@"com.suba.subaapp" forHTTPHeaderField:@"x-suba-api-token"];
    
    return __sharedInstance;
}



+ (instancetype)facebookAPIBaseURL
{
    return [NSURL URLWithString:FacebookAPIBaseURLString];
}



@end


