//
//  SBColorPallet.m
//  Doodling
//
//  Created by Drew on 7/2/14.
//  Copyright (c) 2014 Suba. All rights reserved.
//

#import "SBColorPallet.h"

@implementation SBColorPallet

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        
        self.layer.cornerRadius = 2;
        self.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.8];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
