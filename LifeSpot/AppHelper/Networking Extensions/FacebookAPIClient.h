//
//  FacebookAPIClient.h
//  LifeSpot
//
//  Created by Kwame Nelson on 2/17/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface FacebookAPIClient : AFHTTPSessionManager

+ (instancetype)sharedInstance;
+ (instancetype)facebookAPIBaseURL;

@end

