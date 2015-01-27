//
//  NotificationCell.h
//  Suba
//
//  Created by Kwame Nelson on 9/19/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *senderImageView;

@property (weak, nonatomic) IBOutlet UILabel *notificationMessage;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *notificationTimestamp;

@end
