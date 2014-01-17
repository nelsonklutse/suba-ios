//
//  Privacy.h
//  LifeSpots
//
//  Created by Kwame Nelson on 11/2/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ANYONE @"0"
#define ONLY_MEMBERS @"1"


@interface Privacy : NSObject

@property (strong,nonatomic) NSString *viewPrivacy;
@property (strong,nonatomic) NSString *addPrivacy;

-(id)initWithView:(NSString *)viewPrivacy AddPrivacy:(NSString *)addPrivacy;
@end
