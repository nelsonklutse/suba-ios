//
//  NearbyStreamsHeaderView.h
//  LifeSpot
//
//  Created by Kwame Nelson on 5/29/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NearbyStreamsHeaderView : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UIView *userProfileView;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNumberOfStreamsLabel;
@property (weak, nonatomic) IBOutlet UILabel *streamsLabel;

@property (weak, nonatomic) IBOutlet UILabel *userFullName;
@property (weak, nonatomic) IBOutlet UILabel *userUserName;

@property (weak, nonatomic) IBOutlet UILabel *photosLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfPhotosLabel;



#pragma mark - General Helpers
- (void)makeInitialPlaceholderViewWithSize:(NSInteger)labelSize view:(UIView *)contextView name:(NSString *)person;
- (UIColor *)circleColor;
- (NSString *)initialStringForPersonString:(NSString *)personString;
- (void)fillView:(UIView *)view WithImage:(NSString *)imageURL;
@end
