//
//  LifespotsAPIClient.h
//  Lifespotsapp
//
//  Created by Kwame Nelson on 9/13/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface SubaAPIClient : AFHTTPSessionManager
+ (instancetype)sharedInstance;
+ (instancetype)subaAPIBaseURL;
@end
