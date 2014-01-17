//
//  LifespotsAPIClient.m
//  Lifespotsapp
//
//  Created by Kwame Nelson on 9/13/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//

#import "LifespotsAPIClient.h"

static NSString * const LifeSpotsAPIBaseURLString = @"http://54.201.118.129/";
//static NSString * const LifeSpotsAPIBaseURLString  = @"http://54.200.15.155/";

//static NSString * const LifeSpotsAPIBaseURLString  =  @"http://127.0.0.1:9000/";

//static NSString * const  LifeSpotsAPIBaseURLString  =  @"http://10.1.0.211:9000/";
//static NSString * const  LifeSpotsAPIBaseURLString  = @"http://192.168.1.5:9000/";


@implementation LifespotsAPIClient


+ (instancetype)sharedInstance
{
    //AFNetworkingReachabilityDidChangeNotification
    
    static LifespotsAPIClient *__sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        __sharedInstance = [[LifespotsAPIClient alloc]
                            initWithBaseURL:[NSURL URLWithString:LifeSpotsAPIBaseURLString]
                       sessionConfiguration:configuration];
      AFNetworkReachabilityManager *reachManger = [__sharedInstance reachabilityManager];
        [reachManger setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusNotReachable:
                case AFNetworkReachabilityStatusUnknown:
                    DLog(@"No Internet");
                    [AppHelper showAlert:@"No internet" message:@"We could not detect an internet connection"
                                 buttons:@[@"I'll check"] delegate:nil];
                    
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    DLog(@"Internet available via wifi");
                    break;
                default:
                    break;
            }
        }];
        
    });
    
    return __sharedInstance;
}

+ (instancetype)lifespotsAPIBaseURL
{
    return [NSURL URLWithString:LifeSpotsAPIBaseURLString];
}

@end
