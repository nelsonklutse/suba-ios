//
//  PhotoStreamFooterView.h
//  LifeSpot
//
//  Created by Kwame Nelson on 5/28/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoStreamFooterView : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UILabel *quietHereLabel;
@property (weak, nonatomic) IBOutlet UILabel *inviteFriendsText;
@property (weak, nonatomic) IBOutlet UIButton *emailInviteButton;
@property (weak, nonatomic) IBOutlet UIButton *smsInviteButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteByUsernameButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIButton *otherInviteOptionsButton;

@end
