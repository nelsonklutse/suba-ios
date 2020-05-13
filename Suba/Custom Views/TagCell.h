//
//  TagCell.h
//  Suba
//
//  Created by Kwame Nelson on 3/18/15.
//  Copyright (c) 2015 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TagCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *friendImage;

@property (weak, nonatomic) IBOutlet UIView *friendImageView;
@property (weak, nonatomic) IBOutlet UILabel *friendName;
@property (weak, nonatomic) IBOutlet UILabel *friendUserName;

- (void)fillView:(UIView *)view WithImageURL:(NSString *)imageURL placeholder:(UIImage *)image;
- (void)fillView:(UIView *)view WithImage:(UIImage *)realImage;
- (void)makeInitialPlaceholderView:(UIView *)contextView name:(NSString *)person; 

@end
