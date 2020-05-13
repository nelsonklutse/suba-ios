//
//  InviteView.h
//  Suba
//
//  Created by Kwame Nelson on 10/31/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InviteView : UIView

- (UIView *)popUpView;
- (UILabel *)titleLabel;
- (UIImageView *)senderImageView;
- (UILabel *)inviteMessageLabel;
- (UIButton *)joinStreamButton;

- (void)presentPopUpViewInView:(UIView *)view;
+ (InviteView *)loadCustomViewFromNibFile;


@end
