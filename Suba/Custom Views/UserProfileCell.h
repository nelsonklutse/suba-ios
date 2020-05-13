//
//  UserProfileCell.h
//  LifeSpot
//
//  Created by Kwame Nelson on 6/18/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserProfileCell : UICollectionViewCell


@property (weak, nonatomic) IBOutlet UIImageView *firstPhotoImageView;

@property (weak, nonatomic) IBOutlet UIView *photoGalleryView;

@property (weak, nonatomic) IBOutlet UILabel *streamVenueLabel;
@property (weak, nonatomic) IBOutlet UIView *userNameView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *streamNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfPhotosLabel;
@property (weak, nonatomic) IBOutlet UIImageView *privateStreamImageView;
@property (weak, nonatomic) IBOutlet UIView *firstMemberPhoto;
@property (weak, nonatomic) IBOutlet UIView *secondMemberPhoto;
@property (weak, nonatomic) IBOutlet UIView *thirdMemberPhoto;

//- (void)prepareForGallery:(NSDictionary *)spotInfo index:(NSIndexPath*)indexPath;
- (void)makeInitialPlaceholderView:(UIView *)contextView name:(NSString *)person;
- (UIColor *)circleColor;
- (void)fillView:(UIView *)view WithImage:(NSString *)imageURL;
- (void)setUpBorderWithColor:(CGColorRef)colorRef AndThickness:(CGFloat)height;
- (void)setImageURL:(NSDictionary *)spotInfo index:(NSIndexPath *)indexPath;

@end
