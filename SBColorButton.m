//
//  SBColorButton.m
//  Doodling
//
//  Created by Drew on 6/26/14.
//  Copyright (c) 2014 Suba. All rights reserved.
//

#import "SBColorButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation SBColorButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.layer.cornerRadius = 2;
    
//        self.layer.shadowColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.8].CGColor;
//        self.layer.shadowOffset = CGSizeMake(0.f, 0.f);
//        self.layer.shadowOpacity = 1.f;
//        self.layer.shadowRadius = 0.65f;
//        
//        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.bounds];
//        self.layer.shadowPath = shadowPath.CGPath;
    
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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

- (void)setSelected:(BOOL)selected{
    
    if (selected){
        
        self.layer.borderColor = [UIColor colorWithRed:1.f green:0.f blue:0.f alpha:0.3f].CGColor;
        self.layer.borderWidth = 3;
//        self.layer.cornerRadius = 2;
        
    } else {

        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 0;
        
    }
}

@end
