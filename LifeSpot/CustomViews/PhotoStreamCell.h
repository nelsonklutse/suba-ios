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
@property (weak, nonatomic) IBOutlet UIView *pictureTakerView;
@property (weak, nonatomic) IBOutlet UILabel *numberOfLikesLabel;
@property (weak, nonatomic) IBOutlet UIButton *likePhotoButton;
@property (weak, nonatomic) IBOutlet UILabel *pictureTakerName;

@property (weak, nonatomic) IBOutlet UIImageView *remixedImageView;
@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *photoCardFooterView;
@property (weak, nonatomic) IBOutlet UIButton *toggleDoodleButton;

@property (weak, nonatomic) IBOutlet UILabel *numberOfRemixersLabel;



- (void)setBorderAroundView:(UIView *)view;
- (void)makeInitialPlaceholderView:(UIView *)contextView name:(NSString *)person;
- (UIColor *)circleColor;
-(void)fillView:(UIView *)view WithImage:(NSString *)imageURL;
//- (void)bounceLikeButton;
//- (void)saveInitialBounds;
@end
