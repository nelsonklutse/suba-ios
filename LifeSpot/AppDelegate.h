//
//  AppDelegate.h
//  Tutorial
//
//  Created by Kwame Nelson on 12/16/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SubaTutorialController;
@class MainStreamViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SubaTutorialController *viewController;

//@property (strong,nonatomic) MainStreamViewController *viewControllerForRefresh;

@property (strong,nonatomic) UINavigationController *rootNavController;
@property (strong,nonatomic) UITabBarController *mainTabBarController;
@property (strong,nonatomic) SubaAPIClient *apiBaseURL;
@property (strong,nonatomic) UIViewController *topViewController;

- (UIViewController *)topViewController;
- (void)resetMainViewController;
- (BOOL)fbUserInfoChanged:(NSDictionary<FBGraphUser> *)user;
@end
