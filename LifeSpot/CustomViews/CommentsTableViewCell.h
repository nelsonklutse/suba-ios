//
//  CommentsTableViewCell.h
//  Suba
//
//  Created by Kwame Nelson on 11/28/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HTKDynamicResizingTableViewCell.h>

@interface CommentsTableViewCell : HTKDynamicResizingTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *commentUserName;

@property (weak, nonatomic) IBOutlet UILabel *comment;

@property (weak, nonatomic) IBOutlet UILabel *commentTimestamp;
@end
