//
//  SBWelcomePanel.m
//  Suba
//
//  Created by Kwame Nelson on 12/2/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import "SBWelcomePanel.h"

@implementation SBWelcomePanel


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
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/




- (IBAction)gotosignupscreen:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kGetStartedNotification object:self];
}


@end
