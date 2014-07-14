//
//  LifespotsAPIClient.m
//  Lifespotsapp
//
//  Created by Kwame Nelson on 9/13/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//

#import "SubaAPIClient.h"

static NSString * const SubaAPIBaseURLString = @"http://54.201.118.129/";
//static NSString * const SubaAPIBaseURLString  = @"http://54.200.15.155/";

//static NSString * const SubaAPIBaseURLString  =  @"http://127.0.0.1:9000/";

//static NSString * const  SubaAPIBaseURLString  =  @"http://10.1.0.140:9000/";
//static NSString * const SubaAPIBaseURLString =  @"http://172.20.10.4:9000/";
//static NSString * const SubaAPIBaseURLString =  @"http://api-dev.subaapp.com/";

@implementation SubaAPIClient

+ (instancetype)sharedInstance
{
    static SubaAPIClient *__sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
 
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        __sharedInstance = [[SubaAPIClient alloc]
                            initWithBaseURL:[NSURL URLWithString:SubaAPIBaseURLString]
                       sessionConfiguration:configuration];
    });
    
    [__sharedInstance.requestSerializer setValue:@"com.suba.subaapp-ios" forHTTPHeaderField:@"x-suba-api-token"];
    
    return __sharedInstance;
}

+ (instancetype)subaAPIBaseURL
{
    return [NSURL URLWithString:SubaAPIBaseURLString];
}

@end
