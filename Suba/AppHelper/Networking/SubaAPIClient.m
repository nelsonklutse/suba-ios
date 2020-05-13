//
//  SubaAPIClient.m
//  Suba
//
//  Created by Kwame Nelson on 9/13/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//

#import "SubaAPIClient.h"

//static NSString *const SubaAPIBaseURLString    =  @"http://api.subaapp.com/";

//static NSString * const SubaAPIBaseURLString   =  @"http://54.187.152.149/";

//static NSString * const SubaAPIBaseURLString   =    @"http://192.168.1.3:8080/";

//static NSString * const SubaAPIBaseURLString   =    @"http://127.0.0.1:8080/";

static NSString * const  SubaAPIBaseURLString  =  @"http://dev-suba.cloudapp.net/";

//static NSString * const SubaAPIBaseURLString   =  @"http://172.20.10.3:8080/";
//static NSString * const SubaAPIBaseURLString     =  @"http://suba-dev.subaapp.com/";


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
    [__sharedInstance.requestSerializer setValue:[AppHelper userID] forHTTPHeaderField:@"com.suba.subaapp-token"];
    
    return __sharedInstance;
}


+ (NSURL *)subaAPIBaseURL
{
    return [NSURL URLWithString:SubaAPIBaseURLString];
}



@end
