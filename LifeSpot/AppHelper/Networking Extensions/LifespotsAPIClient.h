//
//  LifespotsAPIClient.h
//  Lifespotsapp
//
//  Created by Kwame Nelson on 9/13/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface LifespotsAPIClient : AFHTTPSessionManager
+ (instancetype)sharedInstance;
+ (instancetype)lifespotsAPIBaseURL;
@end
