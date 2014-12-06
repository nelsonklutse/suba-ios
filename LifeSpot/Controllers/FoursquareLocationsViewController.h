//
//  FoursquareLocationsViewController.h
//  LifeSpots
//
//  Created by Kwame Nelson on 11/3/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Location;

@protocol FourSquareLocationsDelegate;

@interface FoursquareLocationsViewController : UIViewController

@property (strong,nonatomic) id<FourSquareLocationsDelegate> delegate;
@property (strong,nonatomic) Location *currentLocation;
@property (strong,nonatomic) NSMutableArray *locations;
@property (retain,nonatomic,readonly) NSString *currentLocationSelected;
@property (strong,nonatomic,readonly) Location *venueChosen;
@property (strong,nonatomic) NSArray *subaLocations;
@end


@protocol FourSquareLocationsDelegate <NSObject>

- (void)viewController:(FoursquareLocationsViewController *)locationViewcontroller DidSetLocation:(id)location;

@end