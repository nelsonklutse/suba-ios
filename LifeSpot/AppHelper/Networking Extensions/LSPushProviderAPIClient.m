//
//  LSPushProviderAPIClient.m
//  LifeSpots
//
//  Created by Kwame Nelson on 11/25/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "LSPushProviderAPIClient.h"

static NSString * const  LSPushProviderBASEURL  =  @"http://54.201.18.151/";

@implementation LSPushProviderAPIClient

+ (instancetype)sharedInstance
{
    static LSPushProviderAPIClient *__sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        __sharedInstance = [[LSPushProviderAPIClient alloc]
                            initWithBaseURL:[NSURL URLWithString:LSPushProviderBASEURL]
                            sessionConfiguration:configuration];
    });
    
    return __sharedInstance;
}

+(instancetype)LSPushProviderAPIBaseURL
{
    return [NSURL URLWithString:LSPushProviderBASEURL]; 
}


@end
