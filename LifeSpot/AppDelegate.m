//
//  AppDelegate.m
//  Tutorial
//
//  Created by Kwame Nelson on 12/16/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//

#import "AppDelegate.h"
#import "ICETutorialController.h"
#import "SignUpViewController.h"

@implementation AppDelegate

-(LifespotsAPIClient *)apiBaseURL
{
    if (!_apiBaseURL) {
        return [LifespotsAPIClient sharedInstance];
    }
    
    return _apiBaseURL;
}




- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
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
    DLog();
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    
    //Navbar customization
    UIColor *navbarTintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                               green:(77.0f/255.0f)
                                                blue:(20.0f/255.0f)
                                               alpha:1];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    [UINavigationBar appearance].barTintColor = navbarTintColor;
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    NSDictionary *textTitleOptions = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,[UIColor whiteColor],
                                      
                                      NSForegroundColorAttributeName, nil];
    [[UINavigationBar appearance] setTitleTextAttributes:textTitleOptions];
    
    //End of Navbar Customization

    
    // Init the pages texts, and pictures.
    ICETutorialPage *layer1 = [[ICETutorialPage alloc] initWithSubTitle:@"Create"
                                                            description:@"Create a stream and add your location"
                                                            pictureName:@"1.png"];
    ICETutorialPage *layer2 = [[ICETutorialPage alloc] initWithSubTitle:@"Join"
                                                            description:@"Or join an already existing one"
                                                            pictureName:@"2.png"];
    ICETutorialPage *layer3 = [[ICETutorialPage alloc] initWithSubTitle:@"Invite"
                                                            description:@"Invite via Suba,Facebook or SMS"
                                                            pictureName:@"3.png"];
    ICETutorialPage *layer4 = [[ICETutorialPage alloc] initWithSubTitle:@"Capture"
                                                            description:@"Capture moments in your stream"
                                                            pictureName:@"4.png"];
    ICETutorialPage *layer5 = [[ICETutorialPage alloc] initWithSubTitle:@"Share"
                                                            description:@"Share your stream on social media."
                                                            pictureName:@"5.png"];
    
    
    // Set the common style for SubTitles and Description (can be overrided on each page).
    ICETutorialLabelStyle *subStyle = [[ICETutorialLabelStyle alloc] init];
    [subStyle setFont:TUTORIAL_SUB_TITLE_FONT];
    [subStyle setTextColor:TUTORIAL_LABEL_TEXT_COLOR];
    [subStyle setLinesNumber:TUTORIAL_SUB_TITLE_LINES_NUMBER];
    [subStyle setOffset:TUTORIAL_SUB_TITLE_OFFSET];
    
    ICETutorialLabelStyle *descStyle = [[ICETutorialLabelStyle alloc] init];
    [descStyle setFont:TUTORIAL_DESC_FONT];
    [descStyle setTextColor:TUTORIAL_LABEL_TEXT_COLOR];
    [descStyle setLinesNumber:TUTORIAL_DESC_LINES_NUMBER];
    [descStyle setOffset:TUTORIAL_DESC_OFFSET];
    
    // Load into an array.
    NSArray *tutorialLayers = @[layer1,layer2,layer3,layer4,layer5];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    self.rootNavController = [mainStoryboard instantiateInitialViewController];
    
    if (!self.viewController) {
        DLog(@"No VC present");
        self.viewController = (ICETutorialController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"MAIN_TUTORIAL_VC"];
        
        self.viewController.autoScrollEnabled = YES;
        self.viewController.autoScrollLooping = YES;
        self.viewController.autoScrollDurationOnPage = TUTORIAL_DEFAULT_DURATION_ON_PAGE;
        
        [self.viewController setPages:tutorialLayers];
        
        
        // Set the common styles, and start scrolling (auto scroll, and looping enabled by default)
        [self.viewController setCommonPageSubTitleStyle:subStyle];
        [self.viewController setCommonPageDescriptionStyle:descStyle];
        
        __unsafe_unretained typeof(self) weakSelf = self;
        
        // Set button 1 action.
        [self.viewController setButton1Block:^(UIButton *button){
            //DLog(@"Facebook Button pressed.");
            [weakSelf openFBSession];
        }];
        
        // Set button 2 action, stop the scrolling.
        
        [self.viewController setButton2Block:^(UIButton *button){
            //DLog(@"Button 2 pressed.");
            //DLog(@"Auto-scrolling stopped.");
            
            [weakSelf.viewController stopScrolling];
        }];
        
        // Run it.
        [self.viewController startScrolling];
        
        [self.rootNavController setViewControllers:@[self.viewController]];
        self.window.rootViewController = self.rootNavController;
        
        [self.window makeKeyAndVisible];
    }
    
    
    return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    
    
    
    //[self.window makeKeyAndVisible];
    
    [[FBSession activeSession] closeAndClearTokenInformation];
    // Override point for customization after application launch.
    
    // Register application wide default preferences
    NSDictionary *appDefaults = @{
                                  FIRST_NAME : @"",
                                  LAST_NAME : @"",
                                  USER_NAME : @"",
                                  EMAIL : @"",
                                  SESSION : @"lout",
                                  API_TOKEN : @"-1",
                                  PROFILE_PHOTO_URL : @"-1",
                                  FACEBOOK_ID : @"-1",
                                  NUMBER_OF_ALBUMS : @"0",
                                  IS_SPOT_ACTIVE : @"NO",
                                  SPOT_IS_ACTIVE_MESSAGE : @"Camera is active when you are in a spot"
                                  };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    //Configure the network indicator to listen for when we make network requests and show/hide the Network Activity Indicator appropriately
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
     __weak LifespotsAPIClient *weakApiBaseURL = _apiBaseURL;
    [_apiBaseURL.reachabilityManager startMonitoring];
    __weak typeof(self) weakSelf = self;
    [_apiBaseURL.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
       

        NSOperationQueue *opQueue = weakApiBaseURL.operationQueue;
        switch (status) {
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                DLog(@"There is internet coz status - %d",status);
                [AppHelper showNotificationWithMessage:@"Network Connection success"
                                                  type:kSUBANOTIFICATION_SUCCESS
                                      inViewController:[weakSelf topViewController]
                                       completionBlock:nil];
                
                [opQueue setSuspended:NO];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                
                DLog(@"There is no internet coz status - %d",status);
                [AppHelper showNotificationWithMessage:@"No internet connection"
                                                  type:kSUBANOTIFICATION_ERROR
                                      inViewController:[weakSelf topViewController]
                                       completionBlock:nil];
                [opQueue setSuspended:YES];
                break;
        }

    }];
    
    //[self monitorNetworkChanges];
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]){
        
        DLog(@"Class of launch options dictionary with remote notifications KEY - %@\nReal contents - %@",[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] class],[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] description]);
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserDidSignUpNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
       
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        
    }];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserDidSignUpNotification object:nil];
    
   
    
}



-(void)applicationDidEnterBackground:(UIApplication *)application
{
    [self unmonitorNetworkChanges];
     //[[NSNotificationCenter defaultCenter] removeObserver:self name:kUserReloadStreamNotification object:nil];
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    [self monitorNetworkChanges];
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserDidSignUpNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        
    }];
    
    [FBAppEvents activateApp];
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [FBAppCall handleDidBecomeActive];
    
    // If notifications are enabled for this app
    
   /* if (application.enabledRemoteNotificationTypes != UIRemoteNotificationTypeNone) {
        
        if (![[Authenticate userID] isEqualToString:@"-1"]){
            
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            
            [manager GET:@"http://54.201.18.151/fetchnotifications" parameters:@{@"userId": [Authenticate userID]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                //Handle all notifications
                NSString *notifications = [responseObject[@"badge"] stringValue];
                //DLog(@"Notifications  %@",userInfo);
                
                if ([notifications isEqualToString:@"0"]) {
                    [self.tabBarController.tabBar.items[1] setBadgeValue:nil];
                }else{
                    [self.tabBarController.tabBar.items[1] setBadgeValue:notifications];
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                DLog(@"Error - %@", error);
                DLog(@"%@",operation.responseString);
            }];
            
            
        }
        
    }*/
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [FBSession.activeSession close];
    
}


- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *sendThis = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    
    [[LifespotsAPIClient sharedInstance] POST:REGISTER_DEVICE_TOKEN_URL parameters:@{@"token": sendThis, @"userId":[AppHelper userID] } success:^(NSURLSessionDataTask *task, id responseObject) {
        // Lets give this to analytics
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Error - %@",error);
    }];
    
}




-(void)application:(UIApplication *) application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //DLog(@"RECIEVED REMOTE NOTIFS");
    
    //DLog(@"Root View Controller - %@\nChildView Controllers - %@",[self.window.rootViewController class],[[self.window.rootViewController childViewControllers] description]);
    if(application.applicationState == UIApplicationStateActive){
        
        //DLog(@"got while active");
        
        //Handle all notifications
        //NSString *notifications = [userInfo[@"aps"][@"badge"] stringValue];
        //DLog(@"Notifications  %@",userInfo);
        
       /* if ([notifications isEqualToString:@"0"]){
            [self.tabBarController.tabBar.items[1] setBadgeValue:nil];
        }else{
            [self.tabBarController.tabBar.items[1] setBadgeValue:notifications];
        }
        
        self.window.rootViewController = self.tabBarController;
        */
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
        if (status == FBSessionStateOpen){
            
            //[self.fbLoginIndicator stopAnimating];
            
            
            NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"first_name,last_name,username,email,picture.type(large)" forKey:@"fields"];
            
            [FBRequestConnection startWithGraphPath:@"me" parameters:parameters HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                DLog(@"FB Auth Result - %@\nError - %@",result,error);
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
    LifespotsAPIClient *apiClient = [LifespotsAPIClient sharedInstance];
    
    NSOperationQueue *opQueue = apiClient.operationQueue;
    
    [apiClient.reachabilityManager startMonitoring];
    
    [apiClient.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                DLog(@"There is internet coz status - %d",status);
                [opQueue setSuspended:NO];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
            
                DLog(@"There is no internet coz status - %d",status);
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


- (void)unmonitorNetworkChanges
{
    LifespotsAPIClient *apiClient = [LifespotsAPIClient sharedInstance];
    [apiClient.reachabilityManager stopMonitoring];
}



/*#pragma mark - State Preservation and Restoration
-(BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    DLog();
    return YES;
}

-(BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    DLog();
    return YES;
}


- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    DLog(@"View Controller s identifier path - %@",identifierComponents);
    UIViewController *viewController = nil;
    NSString *identifier = [identifierComponents lastObject];
    
    DLog(@"Last identifier on stack - %@",identifier);
    
    //if ([identifier isEqualToString:@"SignUpVC"]) {
        UIStoryboard *storyboard = [coder decodeObjectForKey:UIStateRestorationViewControllerStoryboardKey];
        if (storyboard != nil) {
            viewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
        }
  //  }
    
    return viewController;
}*/





- (UIViewController *)topViewController{
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





@end

