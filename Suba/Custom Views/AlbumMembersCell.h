//
//  AlbumMembersCell.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlbumMembersCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *memberImageView;
@property (weak, nonatomic) IBOutlet UILabel *memberUserNameLabel;

- (void)makeInitialPlaceholderView:(UIView *)contextView name:(NSString *)person;
- (UIColor *)circleColor;
-(void)fillView:(UIView *)view WithImage:(NSString *)imageURL;
@end
