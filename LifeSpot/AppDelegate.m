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
#import <SDImageCache.h>
#import <Crashlytics/Crashlytics.h>


@implementation AppDelegate

-(UITabBarController *)mainTabBarController
{
    if (!_mainTabBarController){
        _mainTabBarController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"MAINTAB_BAR"];
        
        return _mainTabBarController;
    }
    
    return _mainTabBarController;
}

-(SubaTutorialController *)viewController
{
    if (!_viewController) {
        _viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"onboardingController"];
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
    
    // Facebook SDK * login flow *
    // Attempt to handle URLs to complete any auth (e.g., SSO) flow.
    
    /*if ([[url scheme] isEqualToString:@"suba"]){
        DLog(@" custom URL - %@",url);
        NSArray *queryString = [[url query] componentsSeparatedByString: @"="];
        NSString *taskName = [[queryString lastObject] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if ([taskName isEqualToString:@"create-first-stream"]){
            DLog(@"Create forst stream");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"Create First Stream"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            
            
            [alertView show];
            
            
            // Present Create Stream View Controller
            //UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            //CreateStreamViewController *pVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"CreateStreamVC"];
            
            
        } else if ([taskName isEqualToString:@"add-first-photo-to-stream"]) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"Add First Photo To Stream"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
            
        } else if ([taskName isEqualToString:@"request-photos"]){
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"Request Photos"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
            
        } else {
            
            NSArray *queryString = [[url query] componentsSeparatedByString: @"&"];
            
            NSString *taskNameQS = [queryString objectAtIndex:0];
            NSString *streamNameQS = [queryString lastObject];
            
            NSArray *taskNameComp = [taskNameQS componentsSeparatedByString: @"="];
            taskName = [[taskNameComp lastObject] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            NSArray *streamNameComp = [streamNameQS componentsSeparatedByString: @"="];
            NSString *nameOfStream = [[streamNameComp lastObject] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            if ([taskName isEqualToString:@"checkout-public-stream"]){
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                                    message:[NSString stringWithFormat:@"Checkout Public Stream (id): %@",
                                                                             nameOfStream]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil, nil];
                [alertView show];
            }
            
        }
        
        return YES;
        
    }*/

    
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
    }];
}


// Helper method to wrap logic for handling app links.
- (void)handleAppLink:(FBAccessTokenData *)appLinkToken {
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
        // Override point for customization after application launch.
    //self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    //DLog(@"%s",GetMagickVersion(nil));
    
    if ( ![[[NSUserDefaults standardUserDefaults] objectForKey:@"resetNotifications"] isEqualToString:@"no"] ) {
        DLog(@"We need to reset notifications");
        [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:@"no" forKey:@"resetNotifications"];
    //Navbar customization
    UIColor *navbarTintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                               green:(77.0f/255.0f)
                                                blue:(20.0f/255.0f)
                                               alpha:1];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    [UINavigationBar appearance].barTintColor = navbarTintColor;
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    NSDictionary *textTitleOptions = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName, [UIFont fontWithName:@"Helvetica-Light" size:17.0], NSFontAttributeName,nil];
    
    [[UINavigationBar appearance] setTitleTextAttributes:textTitleOptions];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    //End of Navbar Customization
    
    [[UITabBar appearance] setTintColor:navbarTintColor ];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica-Thin" size:13.0f], NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    
    //[self.window makeKeyAndVisible];
    return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Make call to Appirater
    [Appirater setAppId:kSUBA_APP_ID];
    [Appirater setDaysUntilPrompt:3];
    [Appirater setUsesUntilPrompt:5];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
    [Appirater setDebug:NO];
    [Appirater appLaunched:YES]; 
    
   /*
    if (![[AppHelper userID] isEqualToString:@"-1"] && [AppHelper userID] != NULL) {
       
        
       
    }else{*/
        
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
    //[Flurry setCrashReportingEnabled:YES];
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
        
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        
    }];
   
    //[Crashlytics startWithAPIKey:@"a27bd05e578d1948fcca30313c3abd84d390d0f1"];
    
    /*if (![[AppHelper placesCoachMarkSeen] isEqualToString:@"YES"]) {
       [AppHelper setPlacesCoachMark:@"NO"];
    }
    
    if (![[AppHelper nearbyCoachMarkSeen] isEqualToString:@"YES"]) {
        [AppHelper setNearbyCoachMark:@"NO"];
    }
    
    if (![[AppHelper placesCoachMarkSeen] isEqualToString:@"YES"]) {
        [AppHelper setMyStreamCoachMark:@"NO"];
    }
    
    if (![[AppHelper createSpotCoachMarkSeen] isEqualToString:@"YES"]) {
        [AppHelper setCreateSpotCoachMark:@"NO"];
    }
    
    if (![[AppHelper exploreCoachMarkSeen] isEqualToString:@"YES"]) {
        [AppHelper setExploreCoachMark:@"NO"];
    }
    
    if (![[AppHelper watchLocationCoachMarkSeen] isEqualToString:@"YES"]) {
        [AppHelper setWatchLocation:@"NO"]; 
    }
    
    if (![[AppHelper shareStreamCoachMarkSeen] isEqualToString:@"YES"]) {
        [AppHelper setShareStreamCoachMark:@"NO"];
    }*/
    
    //[self.window makeKeyAndVisible];
    
    
    // Check whether we have an update
    //[[Harpy sharedInstance] setAppID:kSUBA_APP_ID];
    //[[Harpy sharedInstance] setAppName:kSUBA_APP_NAME];
    
    // Perform check for new version of app
    //[[Harpy sharedInstance] checkVersion];
    
    //();
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
    [Appirater appEnteredForeground:YES];
    
     [AppHelper increaseAppSessions];
    
            // Session is not open so open the session
            if ([[AppHelper facebookLogin] isEqualToString:@"YES"] || [[AppHelper facebookSession] isEqualToString:@"YES"]){
                
                [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email",@"user_birthday"] allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                    if (session.isOpen) {
                        DLog(@"FBSession Open");
                        if ([[AppHelper facebookLogin] isEqualToString:@"YES"]){
                            NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"first_name,last_name,username,email,picture.type(large)" forKey:@"fields"];
                            
                            [FBRequestConnection startWithGraphPath:@"me" parameters:parameters HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {                                 if (error) {
                                     DLog(@"Updating user fb info error - %@",error);
                                 }
                                 else if (!error){
                                     NSDictionary<FBGraphUser> *user = result;
                                     
                                     [AppHelper setFacebookID:user.id]; // set the facebook id
                                     DLog(@"User facebook Info fetched again - %@",user);
                                     
                                     if ([self fbUserInfoChanged:user]) {
                                         // Make api request to update user profile if any details change
                                         DLog(@"Updating fb info - %@",user);
                                         NSString *pictureURL = [[[user valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
                                         
                                         NSDictionary *params = @{@"id" : [NSString stringWithFormat:@"%@",user.id],
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
    
    
    
    [FBSettings setDefaultAppID:@"563203563717054"];
    [FBAppEvents activateApp];
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [FBAppCall handleDidBecomeActive];
    [application setApplicationIconBadgeNumber:0];
    
    if(application.enabledRemoteNotificationTypes != UIRemoteNotificationTypeNone) {
        
        if (([[AppHelper userID] isEqualToString:@"-1"] || [AppHelper userID] == NULL)){
            
        }else{
            
            [[SubaAPIClient sharedInstance] GET:@"user/notifications/fetch"
                                                parameters:@{@"userId": [AppHelper userID]}
                                                  success:^(NSURLSessionDataTask *task, id responseObject){
            
            // Handle all notifications
            NSString *notifications = [responseObject[@"badgeCount"] stringValue];
                                                      
            if ([notifications isEqualToString:@"0"]) {
                [self.mainTabBarController.tabBar.items[2] setBadgeValue:nil];
            }else{
                [self.mainTabBarController.tabBar.items[2] setBadgeValue:notifications];
            }

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
    
    NSString  *userName = nil;
    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
        userName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
    }else{
        userName = [AppHelper userName];
    }
    

    
    [[SubaAPIClient sharedInstance] POST:REGISTER_DEVICE_TOKEN_URL
                              parameters:@{@"deviceToken": sendThis,
                                           @"userId":[AppHelper userID],
                                           @"deviceType": @"iOS"
                                           } success:^(NSURLSessionDataTask *task, id responseObject){
                                               
        [Flurry logEvent:@"User_Turned_On_Push_Notification" withParameters:@{@"user": userName}];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserRegisterForPushNotification object:nil];
                                               DLog(@"Response: %@\nUser registered",responseObject);
        // Lets give this to analytics
    } failure:^(NSURLSessionDataTask *task, NSError *error){
        DLog(@"Error - %@",error);
        
        [Flurry logEvent:@"Error_Registering_For_Push_Notification" withParameters:@{@"user": userName}];
    }];
}


-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
     DLog(@"Notification Info: %@",userInfo);
    
     //NSString *notifications = [userInfo[@"aps"][@"badge"] stringValue];
    
    if (application.applicationState == UIApplicationStateBackground
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
    
    
    [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email",@"user_birthday"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error){
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
                                                      @"id" :user.id,
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
                            [AppHelper showAlert:@"Authentication Error"
                                         message:@"There was a problem authentication you on our servers. Please wait a minute and try again"
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
    
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
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



@end

