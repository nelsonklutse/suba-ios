//
//  SMSContactsCell.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMSContactsCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *contactImageView;
@property (weak, nonatomic) IBOutlet UILabel *contactNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@end
