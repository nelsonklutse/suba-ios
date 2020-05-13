//
//  LSPushProviderAPIClient.h
//  LifeSpots
//
//  Created by Kwame Nelson on 11/25/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface LSPushProviderAPIClient : AFHTTPSessionManager
+ (instancetype)sharedInstance;
+ (NSURL *)LSPushProviderAPIBaseURL;
@end
