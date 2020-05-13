//
//  ProfileSpotCell.h
//  LifeSpots
//
//  Created by Agana-Nsiire Agana on 10/17/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileSpotCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *userInfoView;
@property (weak, nonatomic) IBOutlet UIImageView *userProfileImage;
@property (weak, nonatomic) IBOutlet UILabel *numberOfSpotsLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfPhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *spotsLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfPhotos;
@property (weak, nonatomic) IBOutlet UILabel *photosLabel;

@end
