//
//  PersonalSpotCell.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/10/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TFScroller.h"

@interface PersonalSpotCell : UICollectionViewCell

@property (retain,nonatomic) UIPhotoGalleryView *pGallery;
@property(nonatomic,retain)	TFScroller *mScroller;

@property (weak, nonatomic) IBOutlet UIView *photoGalleryView;
@property (weak, nonatomic) IBOutlet UILabel *spotVenueLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userNameView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *spotNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfPhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *photosLabel;


- (void)prepareForGallery:(NSDictionary *)spotInfo index:(NSIndexPath*)indexPath;
@end
