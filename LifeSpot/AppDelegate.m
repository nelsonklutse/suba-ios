//
//  AppDelegate.m
//  Tutorial
//
//  Created by Kwame Nelson on 12/16/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//

#import "AppDelegate.h"
#import "SubaTutorialController.h"
#import "ActivityViewController.h"
#import "PhotoStreamViewController.h"
#import "MainStreamViewController.h"
#import "CreateStreamViewController.h"
#import "UserProfileViewController.h"
#import "ActivityViewController.h"
#import <Branch.h>
#import <SDImageCache.h>
#import <Crashlytics/Crashlytics.h>
#import <GooglePlus/GooglePlus.h>



@implementation AppDelegate

-(UITabBarController *)mainTabBarController
{
    if (!_mainTabBarController){
        _mainTabBarController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"MAINTAB_BAR"];
        
        //return _mainTabBarController;
    }
    
    return _mainTabBarController;
}

/*-(MainStreamViewController *)viewControllerForRefresh
{
    DLog(@"NAv: %@",_mainTabBarController.childViewControllers[0]);
   UINavigationController *nv = (UINavigationController *)_mainTabBarController.childViewControllers[0];
   
    DLog(@"NV: %@",nv.childViewControllers);
    _viewControllerForRefresh = (MainStreamViewController *)nv.childViewControllers[0];
    return _viewControllerForRefresh;
}*/


-(SubaTutorialController *)viewController
{
    if (!_viewController) {
        _viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"WalkthroughController"];
    }
    
    return _viewController;
}

-(SubaAPIClient *)apiBaseURL
{
    if (!_apiBaseURL) {
        return [SubaAPIClient sharedInstance];
    } 
    
    
    return _apiBaseURL;
}




- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    DLog(@"url - %@\nSource app: %@\nAnnotation: %@",url,sourceApplication,annotation);
    
    if ([[Branch getInstance] handleDeepLink:url]) {
        return YES;
    }
    
    // Facebook SDK * login flow *
    // Attempt to handle URLs to complete any auth (e.g., SSO) flow.
    
    
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication fallbackHandler:^(FBAppCall *call) {
        // Facebook SDK * App Linking *
        // For simplicity, this sample will ignore the link if the session is already
        // open but a more advanced app could support features like user switching.
        if (call.accessTokenData) {
            if ([FBSession activeSession].isOpen) {
                DLog(@"INFO: Ignoring app link because current session is open.");
            }
            else {
                [self handleAppLink:call.accessTokenData];
            }
        }
    }] ||  [GPPURLHandler handleURL:url
                  sourceApplication:sourceApplication
                         annotation:annotation];
}


// Helper method to wrap logic for handling app links.
- (void)handleAppLink:(FBAccessTokenData *)appLinkToken{
    
    
    // Initialize a new blank session instance...
    FBSession *appLinkSession = [[FBSession alloc] initWithAppID:nil
                                                     permissions:nil
                                                 defaultAudience:FBSessionDefaultAudienceNone
                                                 urlSchemeSuffix:nil
                                              tokenCacheStrategy:[FBSessionTokenCachingStrategy nullCacheInstance]];
    
    [FBSession setActiveSession:appLinkSession];
    // ... and open it from the App Link's Token.
    [appLinkSession openFromAccessTokenData:appLinkToken
                          completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                              // Forward any errors to the FBLoginView delegate.
                              if (error) {
                                  // Let the onboarding view controller
                              }
                          }];
}


-(BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
   
    
    DLog(@"Current App version: %@",[NSString stringWithFormat:@"%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]);
    
    [[NSUserDefaults standardUserDefaults] setValue:@"no" forKey:@"resetNotifications"];
    //Navbar customization
    UIColor *navbarTintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                               green:(77.0f/255.0f)
                                                blue:(20.0f/255.0f)
                                               alpha:1];
    
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    [[UINavigationBar appearance] setBarTintColor:kSUBA_APP_COLOR];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    NSDictionary *textTitleOptions = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName, [UIFont fontWithName:@"Helvetica-Light" size:17.0], NSFontAttributeName,nil];
    
    [[UINavigationBar appearance] setTitleTextAttributes:textTitleOptions];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
    
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    //End of Navbar Customization
    
    [[UITabBar appearance] setTintColor:navbarTintColor ];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica-Thin" size:13.0f], NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    [[UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class],[UIImagePickerController class], [MFMessageComposeViewController class], nil] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearanceWhenContainedIn:[MFMailComposeViewController class],[UIImagePickerController class],[MFMessageComposeViewController class], nil] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    //[self.window makeKeyAndVisible];
    return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Set the minimum background fetch interval to minimum
    //[[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    //[[UIApplication sharedApplication] unregisterForRemoteNotifications];
    
    // Make call to Appirater
    [Appirater setAppId:kSUBA_APP_ID];
    [Appirater setDaysUntilPrompt:3];
    [Appirater setUsesUntilPrompt:5];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
    [Appirater setDebug:NO];
    [Appirater appLaunched:YES]; 
    
        if ([[AppHelper userID] isEqualToString:@"-1"] || [AppHelper userID] == NULL) {
        
        NSDictionary *appDefaults = @{
                                      FIRST_NAME : @"",
                                      LAST_NAME : @"",
                                      USER_NAME : @"",
                                      EMAIL : @"",
                                      SESSION : @"inactive",
                                      API_TOKEN : @"-1",
                                      PROFILE_PHOTO_URL : @"-1",
                                      FACEBOOK_ID : @"-1",
                                      NUMBER_OF_ALBUMS : @"0",
                                      @"resetNotifications" : @"no",
                                      kSUBA_USER_NUMBER_OF_PHOTO_STREAM_ENTRIES : @"0",
                                      NUMBER_OF_APP_SESSIONS : [NSNumber numberWithInteger:0]};

        DLog(@"registering app defaults");
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
        
            
            
    }else{
         DLog(@"userid - %@",[AppHelper userID]);
         self.window.rootViewController = self.mainTabBarController;
    }
    
    
    // Setting up Flurry SDK
    [Flurry startSession:@"RVRXFGG5VQ34NSWMXHFZ"];
    
    //Configure the network indicator to listen for when we make network requests and show/hide the Network Activity Indicator appropriately
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [self monitorNetworkChanges];
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]){
        
        // We are coming from a push notification
        
        NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (userInfo[@"streamId"] && userInfo[@"photoURL"]) {
            // If user liked photo, let's show the photo
            
            [self.mainTabBarController setSelectedIndex:2];
            
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            PhotoStreamViewController *pVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"PHOTOSTREAM_SCENE"];
            
            pVC.spotID = userInfo[@"streamId"];
            self.window.rootViewController = self.mainTabBarController;
            
            UINavigationController *nVC = (UINavigationController *)[self.mainTabBarController viewControllers][2];
            ActivityViewController *aVC = (ActivityViewController *)nVC.childViewControllers[0];
            
            //DLog(@"Tab Bar Controllers - %@",[[nVC childViewControllers] debugDescription]);
            
            if (userInfo[@"doodledPhotoURL"]) {
                [aVC performSegueWithIdentifier:@"ACTIVITY_PHOTO_STREAM"
                                         sender:@{@"streamId" : pVC.spotID,
                                                  @"photoURL" : userInfo[@"photoURL"],
                                                  @"doodledPhotoURL" : userInfo[@"doodledPhotoURL"]
                                                  }];
            }else{
                
                [aVC performSegueWithIdentifier:@"ACTIVITY_PHOTO_STREAM"
                                         sender:@{@"streamId" : pVC.spotID,
                                                  @"photoURL" : userInfo[@"photoURL"]
                                                  }];
            }
            
        }else if (userInfo[@"streamId"]){
            // This notification contains only the streamId
            [self.mainTabBarController setSelectedIndex:2];
            
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            PhotoStreamViewController *pVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"PHOTOSTREAM_SCENE"];
            
            pVC.spotID = userInfo[@"streamId"];
            self.window.rootViewController = self.mainTabBarController;
            
            UINavigationController *nVC = (UINavigationController *)[self.mainTabBarController viewControllers][2];
            ActivityViewController *aVC = (ActivityViewController *)nVC.childViewControllers[0];
            
            [aVC performSegueWithIdentifier:@"ACTIVITY_PHOTO_STREAM" sender:@{@"streamId" : pVC.spotID}];
        }
    }

    [[NSNotificationCenter defaultCenter] addObserverForName:kUserDidSignUpNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        DLog(@"Registering for push notification") ;
        
     if (IS_OS_8_OR_LATER){
            if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            // We register differently on iOS 8
            DLog(@"iOS 8");
            UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
                
            UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
                
            [[UIApplication sharedApplication] registerForRemoteNotifications];
            [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
          }
        } else {
            // use registerForRemoteNotifications
            DLog(@"Remote notifications --- iOS 7");
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        }
    }];
   
    // Set up Branch metrics
    Branch *branch = [Branch getInstance:kBRANCH_API_KEY];
    
    [branch initSessionWithLaunchOptions:launchOptions andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        if (!error) {
            // params are the deep linked params associated with the link that the user clicked before showing up.
            //NSDictionary *referringParams = [branch getFirstReferringParams];
            
            if ([params count] > 0 || [[AppHelper getInviteParams] count] > 0) {
                [AppHelper saveInviteParams:params];
                [self presentPopUpOnTopMostViewController];
            }
            
            DLog(@"deep link data: %@\nReferring Params: %@\nInstall params: %@",[params description],params ,[branch getFirstReferringParams]);
            
        }else DLog(@"Branch error: %@",error.debugDescription);
    }];

    
    
    [Crashlytics startWithAPIKey:@"a27bd05e578d1948fcca30313c3abd84d390d0f1"];
    
    [self.window makeKeyAndVisible];
    
    // Check whether we have an update
    [[Harpy sharedInstance] setAppID:kSUBA_APP_ID];
    [[Harpy sharedInstance] setAppName:kSUBA_APP_NAME];
    
    [[Harpy sharedInstance] setAlertControllerTintColor:kSUBA_APP_COLOR];
    //[[Harpy sharedInstance] setAlertType:HarpyAlertTypeForce];
    [[Harpy sharedInstance] setPresentingViewController:_window.rootViewController];
    
    // Perform check for new version of app
    [[Harpy sharedInstance] checkVersion];

    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:kUserDidSignUpNotification object:nil];
    
}



-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
     [[SDImageCache sharedImageCache] clearDisk];
     [[SDImageCache sharedImageCache] cleanDisk];
     [[SDImageCache sharedImageCache] clearMemory];
}



-(void)applicationDidEnterBackground:(UIApplication *)application
{
    [self unmonitorNetworkChanges];
    
    CLLocationManager *locManager = [[CLLocationManager alloc] init];
    
    [locManager stopUpdatingLocation];
    
     //[[NSNotificationCenter defaultCenter] removeObserver:self name:kUserReloadStreamNotification object:nil];
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    Branch *branch = [Branch getInstance:@"55726832636395855"];
    DLog(@"Referring params: %@",[branch getLatestReferringParams]);
    
    NSDictionary *referringParams = [branch getLatestReferringParams];
    if ([referringParams count] > 0) {
        [AppHelper saveInviteParams:referringParams];
        [self presentPopUpOnTopMostViewController];
    }
   
    [Appirater appEnteredForeground:YES];
    
     [AppHelper increaseAppSessions];
    
            // Session is not open so open the session
            if ([[AppHelper facebookLogin] isEqualToString:@"YES"] || [[AppHelper facebookSession] isEqualToString:@"YES"]){
                
                [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email"] allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                    if (session.isOpen) {
                        DLog(@"FBSession Open");
                        if ([[AppHelper facebookLogin] isEqualToString:@"YES"]){
                            NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"first_name,last_name,username,email,picture.type(large)" forKey:@"fields"];
                            
                            [FBRequestConnection startWithGraphPath:@"me" parameters:parameters HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {                                 if (error) {
                                     DLog(@"Updating user fb info error - %@",error);
                                 }
                                 else if (!error){
                                     NSDictionary<FBGraphUser> *user = result;
                                     
                                     [AppHelper setFacebookID:user.objectID]; // set the facebook id
                                     DLog(@"User facebook Info fetched again - %@",user);
                                     
                                     if ([self fbUserInfoChanged:user]) {
                                         // Make api request to update user profile if any details change
                                         DLog(@"Updating fb info - %@",user);
                                         NSString *pictureURL = [[[user valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
                                         
                                         NSDictionary *params = @{@"id" : [NSString stringWithFormat:@"%@",user.objectID],
                                         FIRST_NAME : user.first_name,
                                         LAST_NAME : user.last_name,
                                        USER_NAME: user.username,
                                         EMAIL : [user valueForKey:@"email"],
                                         @"profilePhoto" : pictureURL
                                     };
                                     
                                         DLog(@" FB Params - %@",params);
                                         
                                         [[SubaAPIClient sharedInstance]
                                          POST:@"fbUser/info/update"
                                          parameters:params
                                          success:^(NSURLSessionDataTask *task, id responseObject) {
                                                           if ([responseObject[STATUS] isEqualToString:ALRIGHT]) {
                                                               DLog(@"Response from server - %@",responseObject);
                                                               [AppHelper savePreferences:responseObject];
                                                               [AppHelper setProfilePhotoURL:user[@"profilePicURL"]];
                                                               [AppHelper setFacebookLogin:@"YES"];
                                                               [AppHelper setFacebookSession:@"YES"];
                                                           } 
                                                       } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                                           
                                                       }];
                                     }
                                 }
                                 
                                 
                             }];
                        }
                    }
                    
                    
                }];
            }
    [self monitorNetworkChanges];
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DLog();
    [FBSettings setDefaultAppID:@"563203563717054"];
    [FBAppEvents activateApp];
    
    [FBAppCall handleDidBecomeActive];
    
    
    
    [application setApplicationIconBadgeNumber:0];
    
    if([[[NSUserDefaults standardUserDefaults] valueForKey:@"REMOTENOTIFICATIONS_REGISTERED"] isEqualToString:@"YES"]) {
        
        if (([[AppHelper userID] isEqualToString:@"-1"] || [AppHelper userID] == NULL)){
            
        }else{
            
            [[SubaAPIClient sharedInstance] GET:@"user/notifications/fetch"
                                                parameters:@{@"userId": [AppHelper userID]}
                                                  success:^(NSURLSessionDataTask *task, id responseObject){
            
            // Handle all notifications
           /* NSString *notifications = [responseObject[@"badgeCount"] stringValue];
                                                      
            if ([notifications isEqualToString:@"0"]) {
                [self.mainTabBarController.tabBar.items[2] setBadgeValue:nil];
            }else{
                [self.mainTabBarController.tabBar.items[2] setBadgeValue:notifications];
            }*/

        }failure:^(NSURLSessionDataTask *task, NSError *error){
            
            DLog(@"Error - %@", error);
            
        }];
      }
   }
    
    [Flurry logEvent:@"App_Started_From_Background"];
    //DLog();
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    //[FBSession.activeSession close];
    
}


- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    //DLog();
    NSString *sendThis = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    [sendThis stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString  *userName = nil;
    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
        userName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
    }else{
        userName = [AppHelper userName];
    }
    

    
    [[SubaAPIClient sharedInstance] POST:REGISTER_DEVICE_TOKEN_URL
                              parameters:@{@"deviceToken": sendThis,
                                           @"userId":[AppHelper userID],
                                           @"deviceType": @"ios"
                                           }
                                success:^(NSURLSessionDataTask *task, id responseObject){
                                               
        [Flurry logEvent:@"User_Turned_On_Push_Notification" withParameters:@{@"user": userName}];
        
        [[NSUserDefaults standardUserDefaults] setValue:@"YES" forKey:@"REMOTENOTIFICATIONS_REGISTERED"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserRegisterForPushNotification object:nil];
                                               DLog(@"Response: %@\nUser registered",responseObject);
        // Lets give this to analytics
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        DLog(@"Error - %@",error);
        
        [Flurry logEvent:@"Error_Registering_For_Push_Notification" withParameters:@{@"user": userName}];
    }];
}



- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    DLog(@" User info: %@",userInfo);
    if (application.applicationState == UIApplicationStateActive) {
        // We'll later show a notification here
        UINavigationController *nVC = (UINavigationController *)[self.mainTabBarController viewControllers][2];
        ActivityViewController *aVC = (ActivityViewController *)nVC.childViewControllers[0];
        
        
       /* DLog(@"nvc - %@",[nVC childViewControllers]);
        
        _notification = [[AFDropdownNotification alloc] init];
        _notification.notificationDelegate = self;
        
        _notification.titleText = @"Update available";
        _notification.subtitleText = @"Do you want to download the update of this file?";
        //notification.image = [UIImage imageNamed:@"update"];
        _notification.topButtonText = @"Accept";
        _notification.bottomButtonText = @"Cancel";
        
        //[notification presentInView:<#(UIView *)#> withGravityAnimation:<#(BOOL)#>]
        
        [_notification presentInView:aVC.view withGravityAnimation:YES];*/
        
        [aVC.tabBarItem setBadgeValue:@"1"];
    }else if (application.applicationState == UIApplicationStateBackground
        || application.applicationState == UIApplicationStateInactive){
       
        if (userInfo[@"streamId"] && userInfo[@"photoURL"]) {
            // If user liked photo, let's show the photo
          
            [self.mainTabBarController setSelectedIndex:2];
            
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            PhotoStreamViewController *pVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"PHOTOSTREAM_SCENE"];
            
            pVC.spotID = userInfo[@"streamId"];
            self.window.rootViewController = self.mainTabBarController;
            
            UINavigationController *nVC = (UINavigationController *)[self.mainTabBarController viewControllers][2];
            ActivityViewController *aVC = (ActivityViewController *)nVC.childViewControllers[0];
            
            [aVC.tabBarItem setBadgeValue:@"1"];
            
            //DLog(@"Tab Bar Controllers - %@",[[nVC childViewControllers] debugDescription]);
            
            if (userInfo[@"doodledPhotoURL"]) {
                [aVC performSegueWithIdentifier:@"ACTIVITY_PHOTO_STREAM"
                                         sender:@{@"streamId" : pVC.spotID,
                                                  @"photoURL" : userInfo[@"photoURL"],
                                                  @"doodledPhotoURL" : userInfo[@"doodledPhotoURL"]
                                                  }];
            }else{
                
            [aVC performSegueWithIdentifier:@"ACTIVITY_PHOTO_STREAM"
                                     sender:@{@"streamId" : pVC.spotID,
                                              @"photoURL" : userInfo[@"photoURL"]
                                              }];
            }
            
        }else if (userInfo[@"streamId"]){
            
            // This notification contains only the streamId
            [self.mainTabBarController setSelectedIndex:2];
            
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            PhotoStreamViewController *pVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"PHOTOSTREAM_SCENE"];
            
            pVC.spotID = userInfo[@"streamId"];
            self.window.rootViewController = self.mainTabBarController;
            
            UINavigationController *nVC = (UINavigationController *)[self.mainTabBarController viewControllers][2];
            ActivityViewController *aVC = (ActivityViewController *)nVC.childViewControllers[0];
            
            [aVC performSegueWithIdentifier:@"ACTIVITY_PHOTO_STREAM" sender:@{@"streamId" : pVC.spotID}];
          
        }
    }
}



- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	DLog(@"Failed to get token, error: %@", error);
}




#pragma mark - Facebook Login
- (void)openFBSession{
    //[self.fbLoginIndicator startAnimating];
    
    
    [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error){
        //DLog(@"Opening FB Session with error - %@\nSession - %@",error,[session debugDescription]);
        
        if (session.isOpen){
            [AppHelper setFacebookSession:@"YES"];
            //[self.fbLoginIndicator stopAnimating];
            
            
            NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"first_name,last_name,username,email,picture.type(large)" forKey:@"fields"];
            
            [FBRequestConnection startWithGraphPath:@"me" parameters:parameters HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                //DLog(@"FB Auth Result - %@\nError - %@",result,error);
                if (!error) {
                    NSDictionary<FBGraphUser> *user = result;
                    
                    NSString *pictureURL = [[[result valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
                    
                    [AppHelper setProfilePhotoURL:pictureURL];
                    
                    NSDictionary *fbSignUpDetails = @{
                                                      @"id" :user.objectID, 
                                                      FIRST_NAME: user.first_name,
                                                      LAST_NAME : user.last_name,
                                                      EMAIL : [user valueForKey:@"email"],
                                                      USER_NAME : user.username,
                                                      @"pass" : @"",
                                                      PROFILE_PHOTO_URL : pictureURL
                                                      };
                    
                    
                    [AppHelper createUserAccount:fbSignUpDetails WithType:FACEBOOK_LOGIN completion:^(id results, NSError *error) {
                        
                        if (!error) {
                            //DLog(@"Response - %@",result);
                             UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                            UIViewController *personalSpotsVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"MAINTAB_BAR"];
                            
                            [self.viewController presentViewController:personalSpotsVC animated:YES completion:nil];
                        }else{
                            DLog(@"Error - %@",error);
                            [AppHelper showAlert:@"Oops!"
                                         message:@"There was a problem logging you in. Try again?"
                                         buttons:@[@"OK"]
                                        delegate:nil];
                           
                        }
                    }];
                    
                    
                }
            }];
        }
    }];
 
}


- (void)monitorNetworkChanges{
    SubaAPIClient *apiClient = [SubaAPIClient sharedInstance];
    
    NSOperationQueue *opQueue = apiClient.operationQueue;
    
    [apiClient.reachabilityManager startMonitoring];
    
    [apiClient.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
               // DLog(@"There is internet coz status - %ld",status);
                /*[AppHelper showNotificationWithMessage:@"Network connection success"
                                                  type:kSUBANOTIFICATION_SUCCESS
                                      inViewController:[self topViewController]
                                       completionBlock:nil];*/
                [opQueue setSuspended:NO];
                break;
            case AFNetworkReachabilityStatusNotReachable:
                //DLog(@"There is no internet coz status - %ld",status);
                [AppHelper showNotificationWithMessage:@"No internet connection"
                                                  type:kSUBANOTIFICATION_ERROR
                                      inViewController:[self topViewController]
                                       completionBlock:nil];
                [opQueue setSuspended:YES];
            default:
            
                //DLog(@"There is no internet coz status - %ld",status);
                [AppHelper showNotificationWithMessage:@"No internet connection"
                                                  type:kSUBANOTIFICATION_ERROR
                                      inViewController:[self topViewController]
                                       completionBlock:nil];
                [opQueue setSuspended:YES];
                break;
        }
        
        /*DLog(@"network reachability chaged");
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter postNotificationName:AFNetworkingReachabilityDidChangeNotification object:nil userInfo:@{ AFNetworkingReachabilityNotificationStatusItem: @(status) }];*/
    }];
}


-(void)unmonitorNetworkChanges
{
    SubaAPIClient *apiClient = [SubaAPIClient sharedInstance];
    [apiClient.reachabilityManager stopMonitoring];
}


// identify we are interested in storing application state, this is called when the app
// is suspended to the background
//
- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

// identify we are interested in re-storing application state,
// this is called when the app is re-launched
//
- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return YES;
}


/*#pragma mark - Background Fetch
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self.viewControllerForRefresh fetchNearbyStreamsInBackgroundWithCompletion:^(BOOL didReceiveNewStreams) {
        if (didReceiveNewStreams){
            DLog(@"Fetch new data");
            [Flurry logEvent:@"Background_Fetch" withParameters:@{@"timestamp":[NSDate date]}];
            completionHandler(UIBackgroundFetchResultNewData);
        }else{
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }];
}*/


/*
 #pragma mark - Restoration

// store data not necessarily related to the user interface,
// this is called when the app is suspended to the background
//
- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder
{
    // encode any state at the app delegate level
}

// reload data not necessarily related to the user interface,
// this is called when the app is re-launched
//
- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder
{
    // decode any state at the app delegate level
    //
    // if you plan to do any asynchronous initialization for restoration -
    // Use these methods to inform the system that state restoration is occuring
    // asynchronously after the application has processed its restoration archive on launch.
    // In the even of a crash, the system will be able to detect that it may have been
    // caused by a bad restoration archive and arrange to ignore it on a subsequent application launch.
    //
    [[UIApplication sharedApplication] extendStateRestoration];
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        
        // do any additional asynchronous initialization work here...
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // done asynchronously initializing, complete our state restoration
            //
            [[UIApplication sharedApplication] completeStateRestoration];
        });
    });
    
}


- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    DLog(@"View Controller identifier path - %@",identifierComponents);
    UIViewController *viewController = nil;
    NSString *identifier = [identifierComponents lastObject];
    
    DLog(@"Last identifier on stack - %@",identifier);
    
    //if ([identifier isEqualToString:@"SignUpVC"]) {
        UIStoryboard *storyboard = [coder decodeObjectForKey:UIStateRestorationViewControllerStoryboardKey];
        if (storyboard != nil) {
            viewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
        }
  //  }
    

   
    DLog(@"Restored View Controller class - %@\n",[viewController class]);
    return viewController;
}*/





- (UIViewController *)topViewController{
    DLog(@"Root View Controller - %@",[[UIApplication sharedApplication].keyWindow.rootViewController class]);
    
    UIViewController *topVC = [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
    
    //DLog(@"Top VC: %@",topVC.p );
    
    return topVC;
}


- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    
    return [self topViewController:presentedViewController];
}


-(void)resetMainViewController
{
    self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    
    __unsafe_unretained typeof(self) weakSelf = self;
    weakSelf.rootNavController = (UINavigationController *)self.window.rootViewController;
    
    [weakSelf.rootNavController setViewControllers:@[self.viewController]];
    DLog(@"Self.view controller - %@ in Root Nav - %@",[self.viewController class],[weakSelf.rootNavController class]);
    weakSelf.window.rootViewController = self.rootNavController;
    
    // Set the minimum background fetch interval to never when the user logs out
    //[[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    [self.window makeKeyAndVisible];
}


-(BOOL)fbUserInfoChanged:(NSDictionary<FBGraphUser> *)user
{
    BOOL infoChanged = NO;
     NSString *pictureURL = [[[user valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
    
    if (![user.username isEqualToString:[AppHelper userName]] ||
        ![user.first_name isEqualToString:[AppHelper firstName]] ||
        ![user.last_name isEqualToString:[AppHelper lastName]] ||
        ![[user valueForKey:@"email"] isEqualToString:[AppHelper userEmail]] ||
        ![pictureURL isEqualToString:[AppHelper profilePhotoURL]]){
        
        DLog(@"User changed facebook info");
        infoChanged = YES;
        
    }
    
    
    
    return infoChanged;
}


- (void)presentPopUpOnTopMostViewController
{
    UIView *rootView = nil;
    
    if([UITabBarController class] == [[self topViewController] class]){
        UITabBarController *tabBarController = (UITabBarController *)[self topViewController];
        UINavigationController *navc = (UINavigationController *)[tabBarController selectedViewController];
        
        
        /*if ([navc.childViewControllers count] > 1){
            
            if ([[navc.childViewControllers lastObject] isKindOfClass:[PhotoStreamViewController class]]) {
                PhotoStreamViewController *photoVC = [navc.childViewControllers lastObject];
                _topViewController = photoVC;
                rootView = photoVC.view;
                DLog(@"We're on the Photo stream VC");
            }
            
            
        }else*/ if([navc.childViewControllers count] == 1){
            
            UIViewController *childVC = navc.childViewControllers[0];
            DLog(@"Child vcs: %@\n Latest object: %@",[navc.childViewControllers debugDescription],[navc.childViewControllers lastObject]);
            if ([childVC isKindOfClass:[MainStreamViewController class]]){
                
                MainStreamViewController *mainVC = (MainStreamViewController *)childVC;
                _topViewController = mainVC;
                rootView = mainVC.view;
                DLog(@"We're on the main stream controller class");
                
            }
        else if([childVC isKindOfClass:[UserProfileViewController class]]){
            
            UserProfileViewController *userVC = (UserProfileViewController *)childVC;
            _topViewController = userVC;
            rootView = userVC.view;
            DLog(@"We're on the User profile controller class");
            
        }else if ([childVC isKindOfClass:[ActivityViewController class]]){
            ActivityViewController *acVC = (ActivityViewController *)childVC;
            _topViewController = acVC;
            rootView = acVC.view;
            DLog(@"We're on the Activity controller class");
        }
      }
        
    }else if ([UINavigationController class] == [[self topViewController] class]){
        UINavigationController *navc = (UINavigationController *)[self topViewController];
        UIViewController *vc = (SubaTutorialController *)navc.childViewControllers[0];
        _topViewController = vc;
        rootView = vc.view;
       DLog(@"Child controllers: %@\nCHild vc %@",[[navc childViewControllers] debugDescription],[vc class]);
    }
    
    [self setUpPopView:rootView];
}


- (void)setUpPopView:(UIView *)rootView
{
    
    DLog(@"Root view has pop up view %@",[rootView viewWithTag:4]);
    
    if (![rootView viewWithTag:4]) { // Only add this view if there's no view showing
        // Do we have some referring params stored?
        NSMutableArray *pendingStreamInvites = [AppHelper getInviteParams];
        DLog(@"Pending stream Invite :%lu",(unsigned long)[pendingStreamInvites count]);
    
      if ([pendingStreamInvites count] > 0) {
        // There is only one pending streams invite so let's show the popUpView
        NSDictionary *referringParams = (NSDictionary *)[pendingStreamInvites lastObject];
        
        UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"InviteView" owner:nil options:nil] objectAtIndex:0];
        view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"filter"]];
        
        //Get the actual pop up and animate  and set target actions for Join stream button;
        UIView *popView = [view viewWithTag:4];
        popView.alpha = 0;
        
        //UILabel *popUpTitleLabel = (UILabel *)[popView viewWithTag:10];
        UIImageView *popUpImageView = (UIImageView *)[popView viewWithTag:20];
        UILabel *popUpMessgaeLabel = (UILabel *)[popView viewWithTag:40];
        UIButton *joinStreamButton = (UIButton *)[popView viewWithTag:30];
        UIActivityIndicatorView *joiningStreamActivityIndicatorView = (UIActivityIndicatorView *)[view viewWithTag:50];
        
        DLog(@"Top view controller: %@",[_topViewController class]);
        if ([_topViewController isKindOfClass:[SubaTutorialController class]]) {
            // Show the log in and sign up views and hide the join stream button
            CGRect originalPopUpFrame = popView.frame;
            CGRect newPopUpFrame = CGRectMake(originalPopUpFrame.origin.x, originalPopUpFrame.origin.y+ 30, originalPopUpFrame.size.width, originalPopUpFrame.size.height);
            
            popView.frame = newPopUpFrame;
            joinStreamButton.hidden = YES;
            joiningStreamActivityIndicatorView.hidden = YES;
            
            UIButton *logInButton = (UIButton *)[popView viewWithTag:70];
            UIButton *signUpButton = (UIButton *)[popView viewWithTag:60];
            logInButton.hidden = NO;
            signUpButton.hidden = NO;
            
            [logInButton addTarget:self action:@selector(logIn:) forControlEvents:UIControlEventTouchUpInside];
            [signUpButton addTarget:self action:@selector(signUp:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        // Set info and image for pop up
        [popUpImageView setImageWithURL:[NSURL URLWithString:referringParams[@"senderPhoto"]] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
        popUpMessgaeLabel.text = [NSString stringWithFormat:@"%@ has invited you to join the %@ photo stream",referringParams[@"sender"],referringParams[@"streamName"]];
          [popUpMessgaeLabel sizeToFit];
        [joinStreamButton addTarget:self action:@selector(joinStream:) forControlEvents:UIControlEventTouchUpInside];
        
       
            [rootView addSubview:view];
            
            [self animatePopUpView:popView];
        }
        
        
    }
    
    
    
}

- (void)animatePopUpView:(UIView *)popUpView
{
    CGRect originalFrame = popUpView.frame;
    CGRect newframe = CGRectMake(popUpView.frame.origin.x, popUpView.frame.origin.y-popUpView.frame.size.height, popUpView.frame.size.width,popUpView.frame.size.height);
    
    [UIView transitionWithView:popUpView
                      duration:.7
                       options:UIViewAnimationOptionTransitionFlipFromTop animations:^{
                           popUpView.alpha = 0.2;
                           popUpView.frame = newframe;
                           popUpView.frame = originalFrame;
                           
                           popUpView.alpha = 1;
                           
    } completion:nil];
    
}


-(IBAction)joinStream:(UIButton *)sender
{
    sender.enabled = NO;
    UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"InviteView" owner:nil options:nil] objectAtIndex:0];
    UIActivityIndicatorView *joiningStreamActivityIndicatorView = (UIActivityIndicatorView *)[view viewWithTag:50];
    joiningStreamActivityIndicatorView.hidden = NO;
    
    Branch *branch = [Branch getInstance:@"55726832636395855"];
    NSDictionary *params = [branch getLatestReferringParams];
    
    if ([params count] > 0) {
        
        // Prepare info for segue
        NSString *numberOfPhotos = params[@"photos"];
        NSString *streamName = params[@"streamName"];
        NSString *streamId = params[@"streamId"];
        NSString *streamCode = params[@"streamCode"];
        
        NSDictionary *inviteInfo = @{@"photos":numberOfPhotos,@"spotName":streamName,@"spotId":streamId};
        
        if ([_topViewController isKindOfClass:[MainStreamViewController class]]) {
            joiningStreamActivityIndicatorView.hidden = NO;
            [joiningStreamActivityIndicatorView startAnimating];
            DLog(@"Indicator visibility? %i",joiningStreamActivityIndicatorView.isHidden);
            sender.titleLabel.text = @"Joining stream...";
            [sender sizeToFit];
            //DLog(@"Performing segue from MainStreamViewController");
            MainStreamViewController *mainViewController = (MainStreamViewController *)_topViewController;
            
            
            [mainViewController joinSpot:streamCode data:inviteInfo completion:^(id results, NSError *error){
                sender.enabled = YES;
                [joiningStreamActivityIndicatorView stopAnimating];
                sender.titleLabel.text = @"Join stream";
                [sender sizeToFit];
                [self dismissPopUpView:sender.superview completion:nil];
                if (!error) {
                    
                    [mainViewController performSegueWithIdentifier:kPhotosStreamSegue sender:inviteInfo];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                    
                }else{
                    DLog(@"Error - %@",error);
                    [AppHelper showAlert:@"Oops!"
                                 message:@"Something went wrong. Try again?"
                                 buttons:@[@"OK"] delegate:nil];
                }
            }];
            
        }else if([_topViewController isKindOfClass:[UserProfileViewController class]]){
            
            joiningStreamActivityIndicatorView.hidden = NO;
            [joiningStreamActivityIndicatorView startAnimating];
            DLog(@"Indicator visibility? %i",joiningStreamActivityIndicatorView.isHidden);
            sender.titleLabel.text = @"Joining stream...";
            [sender sizeToFit];
            UserProfileViewController *userViewController = (UserProfileViewController *)_topViewController;
            
            [userViewController joinSpot:streamCode data:inviteInfo completion:^(id results, NSError *error){
                sender.enabled = YES;
                [joiningStreamActivityIndicatorView stopAnimating];
                [self dismissPopUpView:sender.superview completion:nil];
                sender.titleLabel.text = @"Join stream";
                [sender sizeToFit];
                if (!error){
                    [userViewController performSegueWithIdentifier:kPhotosStreamSegue sender:inviteInfo];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                    
                }else{
                    DLog(@"Error - %@",error);
                    [AppHelper showAlert:@"Oops!"
                                 message:@"Something went wrong. Try again?"
                                 buttons:@[@"OK"] delegate:nil];
                }
            }];
        }else if ([_topViewController isKindOfClass:[ActivityViewController class]]){
            joiningStreamActivityIndicatorView.hidden = NO;
            [joiningStreamActivityIndicatorView startAnimating];
            DLog(@"Indicator visibility? %i",joiningStreamActivityIndicatorView.isHidden);
            sender.titleLabel.text = @"Joining stream...";
            [sender sizeToFit];
            ActivityViewController *activityViewController = (ActivityViewController *)_topViewController;
        
            [activityViewController joinSpot:streamCode data:inviteInfo completion:^(id results, NSError *error){
                sender.enabled = YES;
                [joiningStreamActivityIndicatorView stopAnimating];
                [self dismissPopUpView:sender.superview completion:nil];
                sender.titleLabel.text = @"Join stream";
                [sender sizeToFit];
                if (!error){
                    [activityViewController performSegueWithIdentifier:@"ACTIVITY_PHOTO_STREAM" sender:@{@"streamId" : streamId}];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                    
                }else{
                    DLog(@"Error - %@",error);
                    [AppHelper showAlert:@"Oops!"
                                 message:@"Something went wrong. Try again?"
                                 buttons:@[@"OK"] delegate:nil];
                }
            }];

            
        }else{
            [self dismissPopUpView:sender.superview completion:nil];
        }

    }
}


-(IBAction)logIn:(UIButton *)sender
{
    SubaTutorialController *firstScreen = (SubaTutorialController *)_topViewController;
    //[self dismissPopUpView:sender.superview completion:nil];
    [firstScreen performSegueWithIdentifier:@"LogInScreen" sender:nil];
}


-(IBAction)signUp:(UIButton *)sender
{
    SubaTutorialController *firstScreen = (SubaTutorialController *)_topViewController;
    [firstScreen showSignUpOptions];
   
}


-(void)dismissPopUpView:(UIView *)popUpView  completion:(void (^)(BOOL finished))completionBlock
{
    // Get the current referring params
    Branch *branch = [Branch getInstance:@"55726832636395855"];
    NSDictionary *params = [branch getLatestReferringParams]; 
    
    CGRect newframe = CGRectMake(popUpView.frame.origin.x, popUpView.frame.origin.y+popUpView.frame.size.height, popUpView.frame.size.width,popUpView.frame.size.height);
    
    [UIView transitionWithView:popUpView
                      duration:.3
                       options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                           popUpView.alpha = 1.0;
                           //popUpView.frame = originalFrame;
                           popUpView.frame = newframe;
                           
                           popUpView.alpha = 0;
                           
                       } completion:^(BOOL finished) {
                           [popUpView.superview removeFromSuperview];
                           [AppHelper clearPendingInvites:params];
                           //completionBlock(finished);
                       }];
    
    
    
}


/*-(void)dropdownNotificationTopButtonTapped {
    
    NSLog(@"Top button tapped");
}

-(void)dropdownNotificationBottomButtonTapped {
    
    NSLog(@"Bottom button tapped");
}*/

@end

