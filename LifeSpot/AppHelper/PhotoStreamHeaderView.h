//
//  PhotoStreamHeaderViewCollectionReusableView.h
//  Suba
//
//  Created by Kwame Nelson on 12/1/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoStreamHeaderView : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UIView *headerViewContainer;

@property (weak, nonatomic) IBOutlet UILabel *streamNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *streamLocationLabel;

@property (weak, nonatomic) IBOutlet UILabel *numberOfPhotosLabel;

@property (weak, nonatomic) IBOutlet UILabel *numberOfMembers;

@property (weak, nonatomic) IBOutlet UILabel *photosLabel;

@property (weak, nonatomic) IBOutlet UILabel *membersLabel;

@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;

@property (weak, nonatomic) IBOutlet UIButton *inviteFriendsButton;

@property (weak, nonatomic) IBOutlet UIButton *sortStreamButton;

@property (weak, nonatomic) IBOutlet UILabel *sortStreamFilterLabel;



@end
