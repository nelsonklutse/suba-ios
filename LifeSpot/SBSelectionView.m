//
//  SBSelectionView.m
//  Doodling
//
//  Created by Nelson Klutse on 7/2/14.
//  Copyright (c) 2014 Suba. All rights reserved.


#import "SBSelectionView.h"

@implementation SBSelectionView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.layer.borderWidth = 2;
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 2;
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)setActiveOnButton:(UIButton *)button
{
   self.layer.borderColor = button.backgroundColor.CGColor;
   [self animateToSelectedButton:button.center];
}

- (void)animateToSelectedButton:(CGPoint)position
{
    [UIView animateWithDuration:0.1f animations:^{
        self.hidden = YES;
        self.center = position;
    } completion:^(BOOL finished) {
        self.hidden = NO;
    }];
}

@end
