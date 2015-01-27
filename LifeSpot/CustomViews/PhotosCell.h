//
//  Photos.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/20/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotosCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *spotVenue;

@property (retain, nonatomic) IBOutlet UIView *photoGalleryView;
@property (weak, nonatomic) IBOutlet UILabel *spotName;

//- (void)prepareForGallery:(NSDictionary *)allSpots index:(NSIndexPath*)indexPath;

//- (void)prepareForGallery:(NSDictionary *)spotInfo index:(NSIndexPath*)indexPath;
@end
