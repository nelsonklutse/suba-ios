//
//  MainStreamViewController.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/7/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMScrollingNavbarViewController.h>

@interface MainStreamViewController : AMScrollingNavbarViewController

@property BOOL nearbyNeedsUpdate;
@property BOOL myStreamsNeedsUpdate;
@property BOOL placesNeedsUpdate;

@end
