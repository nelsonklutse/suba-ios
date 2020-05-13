//
//  PhotoTakerCell.h
//  Suba
//
//  Created by Kwame Nelson on 12/15/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoTakerCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *photoTakerImage;

@property (weak, nonatomic) IBOutlet UILabel *photoTakerName;
@property (weak, nonatomic) IBOutlet UILabel *photosLabel;

@end
