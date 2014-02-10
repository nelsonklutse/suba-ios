//
//  ExplorePlacesCell.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/17/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExplorePlacesCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *venueNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *venueIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *venueDistanceLabel;
@property (weak, nonatomic) IBOutlet UIButton *followPlaceButton;

@end
