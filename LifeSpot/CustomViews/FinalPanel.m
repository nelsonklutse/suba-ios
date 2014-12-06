//
//  FinalPanel.m
//  Suba
//
//  Created by Kwame Nelson on 12/2/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import "FinalPanel.h"
#import "MYBlurIntroductionView.h"

@implementation FinalPanel

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

/*-(void)panelDidAppear
{
    //[self.parentIntroductionView setEnabled:NO];
}

-(void)panelDidDisappear
{
    //[self.parentIntroductionView setEnabled:YES];
}*/


- (IBAction)getStartedTapped:(id)sender
{
   [[NSNotificationCenter defaultCenter] postNotificationName:kGetStartedNotification object:self];
}


@end
