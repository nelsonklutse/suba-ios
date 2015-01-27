//
//  CommentsTableViewCell.m
//  Suba
//
//  Created by Kwame Nelson on 11/28/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import "CommentsTableViewCell.h"

@implementation CommentsTableViewCell

- (void)awakeFromNib {
    // Initialization code
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    
    [self.commentUserName setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.commentUserName setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.commentTimestamp setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.commentTimestamp setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.comment setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.comment setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    
    // Set max layout width for all multi-line labels
    // This is required for any multi-line label. If you
    // do not set this, you'll find the auto-height will not work
    // this is because "intrinsicSize" of a label is equal to
    // the minimum size needed to fit all contents. So if you
    // do not have a max width it will not constrain the width
    // of the label when calculating height.
    
    //CGSize defaultSize = [[self class] defaultCellSize];
    self.comment.preferredMaxLayoutWidth = 255 - 5;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
