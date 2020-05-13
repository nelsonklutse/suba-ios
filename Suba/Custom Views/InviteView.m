//
//  InviteView.m
//  Suba
//
//  Created by Kwame Nelson on 10/31/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import "InviteView.h"

@implementation InviteView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
       self = (InviteView *)[self setUpView];
    }
    
    return self;
}


-(id)initWithCoder:(NSCoder *)aDecoder
{
    
    self = [super initWithCoder:aDecoder];
    if (self){
        self = (InviteView *)[self setUpView];
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


-(UIView *)popUpView
{
    return [self viewWithTag:100];
}

-(UILabel *)titleLabel
{
    return (UILabel *)[self viewWithTag:10];
}

-(UIImageView *)senderImageView
{
    return (UIImageView *)[self viewWithTag:20];
}

-(UILabel *)inviteMessageLabel
{
    return (UILabel *)[self viewWithTag:40];
}

-(UIButton *)joinStreamButton
{
    return (UIButton *)[self viewWithTag:30];
}



+ (InviteView *)loadCustomViewFromNibFile 
{
    return [[[NSBundle mainBundle] loadNibNamed:@"InviteView" owner:nil options:nil] objectAtIndex:0];
    
}

-(void)presentPopUpViewInView:(UIView *)view
{
    // DLog(@"Presenting popUp in view: %@",[view debugDescription]);
    UIView *popUpView = [self popUpView];
    popUpView.hidden = NO;
    
    [view addSubview:popUpView];
    
   /* [UIView transitionWithView:popUpView duration:.8 options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
        popUpView.alpha = .6;
    } completion:^(BOOL finished) {
        popUpView.alpha = 1.0;
    }];*/
}


-(void)dismissPopUpView
{
   [[self popUpView] removeFromSuperview];
}



-(UIView *)setUpView
{
   return [[[NSBundle mainBundle] loadNibNamed:@"InviteView" owner:nil options:nil] objectAtIndex:0];
}


@end
