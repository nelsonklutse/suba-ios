//
//  PhotoStreamCell.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/14/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoStreamCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *photoCardImage;

@property (weak, nonatomic) IBOutlet UIView *loadingPictureView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingPictureIndicator;

@property (weak, nonatomic) IBOutlet UIImageView *pictureTakerView;
@property (weak, nonatomic) IBOutlet UILabel *numberOfLikesLabel;
@property (weak, nonatomic) IBOutlet UIButton *likePhotoButton;
@property (weak, nonatomic) IBOutlet UILabel *pictureTakerName;





//- (void)bounceLikeButton;
//- (void)saveInitialBounds;
@end
