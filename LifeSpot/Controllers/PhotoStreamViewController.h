//
//  PhotoStreamViewController.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/14/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kSpot = 0,
    kPhoto
} Mutant;

typedef enum{
    kTakeCamera = 0,
    kGallery
}PhotoSourceType;


@interface PhotoStreamViewController : UIViewController

@property (strong,nonatomic) NSMutableArray *photos;
@property (strong,nonatomic) NSString *spotName;
@property (strong,nonatomic) NSString *spotID;
@property NSInteger numberOfPhotos;
@end