//
//  FoursquareVenueCell.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/8/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FoursquareVenueCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *venueIcon;

@property (weak, nonatomic) IBOutlet UILabel *venueName;

@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;

@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@end
