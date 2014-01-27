//
//  AppDelegate.h
//  Tutorial
//
//  Created by Kwame Nelson on 12/16/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ICETutorialController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ICETutorialController *viewController;
@property (strong,nonatomic) UINavigationController *rootNavController;

@property (strong,nonatomic) LifespotsAPIClient *apiBaseURL;
@end
