//
//  ProfileSpotsHeaderView.h
//  LifeSpots
//
//  Created by Kwame Nelson on 11/19/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileSpotsHeaderView : UICollectionReusableView

//@property(weak,nonatomic) IBOutlet UIImageView *bgImage;
@property(weak,nonatomic) IBOutlet UILabel *spotTitle;
@property (weak, nonatomic) IBOutlet UIImageView *locIcon;
@property (weak, nonatomic) IBOutlet UILabel *spotVenue;

@end
