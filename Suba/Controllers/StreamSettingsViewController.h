//
//  AlbumSettingsViewController.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StreamSettingsViewController : UIViewController
@property UIViewController *whereToUnwind;

@property (copy,nonatomic) NSString *spotName;
@property (strong,nonatomic) NSDictionary *spotInfo;
@property (strong,nonatomic) NSString *spotID;
@property (strong,nonatomic) NSString *streamCreator;

@end
