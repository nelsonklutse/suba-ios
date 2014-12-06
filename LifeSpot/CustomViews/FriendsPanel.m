//
//  FriendsPanel.m
//  Suba
//
//  Created by Kwame Nelson on 12/2/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import "FriendsPanel.h"

@implementation FriendsPanel

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (IBAction)getStartedButtonTapped:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kGetStartedNotification object:self];
}
@end
