//
//  PlacesWatchingStreamCell.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/30/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlacesWatchingStreamCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *photoGalleryView;
@property (weak, nonatomic) IBOutlet UIImageView *userNameView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *spotNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfPhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *photosLabel;
@property (weak, nonatomic) IBOutlet UIImageView *privateStreamImageView;

//- (void)prepareForGallery:(NSDictionary *)spotInfo index:(NSIndexPath*)indexPath;
@end
