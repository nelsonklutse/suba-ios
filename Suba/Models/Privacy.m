//
//  Privacy.m
//  LifeSpots
//
//  Created by Kwame Nelson on 11/2/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "Privacy.h"

@implementation Privacy

-(id)initWithView:(NSString *)viewPrivacy AddPrivacy:(NSString *)addPrivacy{
    if (self = [super init]) {
        self.viewPrivacy = viewPrivacy;
        self.addPrivacy = addPrivacy;
    }
    return self;
}

@end
