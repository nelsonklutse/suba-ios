//
//  Authenticate.m
//  Pixelfly
//
//  Created by Kwame Nelson on 8/26/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//

#import "AppHelper.h"
#import "SubaAPIClient.h"
#import "User.h"

@interface AppHelper()
+ (void)clearUserSession;
@end


@implementation AppHelper

+(NSString *)kindOfDeviceScreen
{
    NSString *deviceScreenType = nil;
    
    if ([[UIScreen mainScreen] respondsToSelector: @selector(scale)]){
        
        CGSize result = [[UIScreen mainScreen] bounds].size;
        CGFloat scale = [UIScreen mainScreen].scale;
        result = CGSizeMake(result.width * scale, result.height * scale);
        
        if(result.height == 960){
            //DEVICE SCREEN IS iPHONE 4
            deviceScreenType = kIPHONE_4_SCREEN;
        }
        if(result.height == 1136){
            //DEVICE SCREEN IS iPHONE 5
            deviceScreenType = kIPHONE_5_SCREEN;
        }
    }
        return deviceScreenType;
}

+ (BOOL)validateEmail:(NSString *)string {
    
    // lowercase the email for proper validation
    string = [string lowercaseString];
    
    // regex for email validation
    NSString *emailRegEx =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    
    NSPredicate *regExPredicate =
    [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    BOOL myStringMatchesRegEx = [regExPredicate evaluateWithObject:string];
    
    return myStringMatchesRegEx;
    
}

+ (BOOL)CheckPasswordMinLength:(NSInteger *)minLength password:(NSString *)string {
    return ((NSInteger *)[string length] < minLength) ? NO:YES;
}

+ (void)saveSessionWithOptions:(NSArray *)options
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setValue:options[0] forKey:FIRST_NAME];
    [userDefaults setValue:options[1] forKey:LAST_NAME];
    [userDefaults setValue:options[2] forKey:USER_NAME];
    [userDefaults setValue:options[3] forKey:EMAIL];
    [userDefaults setValue:options[4] forKey:SESSION];
    [userDefaults setValue:options[5] forKey:API_TOKEN];
    [userDefaults setValue:options[6] forKey:FACEBOOK_ID];
    
    [userDefaults setValue:options[7] forKey:NUMBER_OF_ALBUMS];
    
    [userDefaults synchronize];
}





+ (void)logout
{
    [self clearUserSession];
    [self setUserSession:@"l-out"];
}


+ (void)clearUserSession
{
    NSUserDefaults *userDefaults =  [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = @{
                                  FIRST_NAME : @"",
                                  LAST_NAME : @"",
                                  USER_NAME : @"",
                                  EMAIL : @"",
                                  SESSION : @"lout",
                                  API_TOKEN : @"-1",
                                  FACEBOOK_ID : @"-1",
                                  NUMBER_OF_ALBUMS : @"0",
                                  PROFILE_PHOTO_URL : @""
                                };
    
    //[userDefaults registerDefaults:appDefaults];
    [AppHelper savePreferences:appDefaults];
    [userDefaults setValue:@"-1" forKey:FACEBOOK_ID];
    [userDefaults synchronize];
    
    // Clear facebook data if user loggedIn using facebook
    if ([FBSession activeSession]) {
        [[FBSession activeSession] closeAndClearTokenInformation];
        [AppHelper setFacebookSession:@"NO"];
        [AppHelper setFacebookLogin:@"NO"];
    }
}


+ (NSString *)userID
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:API_TOKEN];
}


+ (NSString *)userEmail
{
   NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:EMAIL];
}

+ (NSString *)facebookID
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:FACEBOOK_ID];
}

+ (void)setFacebookID:(NSString *)fbID{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:fbID forKey:FACEBOOK_ID];
    [userDefaults synchronize];
}

+ (NSString *)firstName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:FIRST_NAME];
}

+ (NSString *)lastName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:LAST_NAME];
}

+ (NSString *)userName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:USER_NAME];
}

+(NSInteger)numberOfAlbums
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *albums =  [userDefaults valueForKey:NUMBER_OF_ALBUMS];
    return [albums integerValue];
}

+ (void)updateNumberOfAlbums:(NSInteger)update
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *albums = [userDefaults valueForKey:NUMBER_OF_ALBUMS];
    
    long albumCount = [albums intValue] + update;
    
    [userDefaults setValue:[NSString stringWithFormat:@"%li",albumCount] forKey:NUMBER_OF_ALBUMS];
    
    [userDefaults synchronize];
}


+(void)setFirstName:(NSString *)firstName
{
   NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:firstName forKey:FIRST_NAME];
    [userDefaults synchronize];
}

+(void)setLastName:(NSString *)lastName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:lastName forKey:LAST_NAME];
    [userDefaults synchronize];
}

+(void)setUserName:(NSString *)userName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:userName forKey:USER_NAME];
    [userDefaults synchronize];
}

+(void)setEmail:(NSString *)email
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:email forKey:EMAIL];
    [userDefaults synchronize];
}


+ (void)setProfilePhotoURL:(NSString *)photoURL
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:photoURL forKey:PROFILE_PHOTO_URL];
    [userDefaults synchronize];
}

+ (NSString *)profilePhotoURL
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:PROFILE_PHOTO_URL];
}

+ (void)setSpotActive:(NSString *)active message:(NSString *)cameraActiveMessage
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:active forKey:IS_SPOT_ACTIVE];
    [userDefaults setValue:cameraActiveMessage forKey:SPOT_IS_ACTIVE_MESSAGE];
    [userDefaults synchronize];
}

+ (NSString *)spotActive
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:IS_SPOT_ACTIVE];
}

+ (void)savePreferences:(NSDictionary *)prefs
{
   NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([prefs objectForKey:API_TOKEN]) {
        [userDefaults setValue:prefs[API_TOKEN] forKey:API_TOKEN];
    }
    
    if ([prefs objectForKey:EMAIL]) {
    [userDefaults setValue:prefs[EMAIL] forKey:EMAIL];
    }
    
    if ([prefs objectForKey:USER_NAME]) {
    [userDefaults setValue:prefs[USER_NAME] forKey:USER_NAME];
    }
    
    if ([prefs objectForKey:FIRST_NAME]) {
        [userDefaults setValue:prefs[FIRST_NAME] forKey:FIRST_NAME];
    }
    if ([prefs objectForKey:LAST_NAME]) {
        [userDefaults setValue:prefs[LAST_NAME] forKey:LAST_NAME];
    }
    
    if ([prefs objectForKey:PROFILE_PHOTO_URL]) {
        [userDefaults setValue:prefs[PROFILE_PHOTO_URL] forKey:PROFILE_PHOTO_URL];
    }
    
    if ([prefs objectForKey:FACEBOOK_ID]) {
        [userDefaults setValue:prefs[@"id"] forKey:FACEBOOK_ID];
    }
    
    if ([prefs objectForKey:SESSION]) {
        [userDefaults setValue:prefs[SESSION] forKey:SESSION];
    }
    
    [userDefaults synchronize];
}

+ (void)setActiveSpotID:(NSString *)spotId
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:spotId forKey:SPOT_ID];
    
    [userDefaults synchronize];
}

+ (NSString *)activeSpotId
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:SPOT_ID];
}


+ (NSString *)facebookLogin
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:FBLOGIN];
}


+(void)setFacebookLogin:(NSString *)fbLogin
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:fbLogin forKey:FBLOGIN];
    
    [userDefaults synchronize];
}


+ (NSString *)facebookSession
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:FB_SESSION];
}

+(void)setFacebookSession:(NSString *)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:flag forKey:FB_SESSION];
    
    [userDefaults synchronize];
}


+(void)setPlacesCoachMark:(NSString *)flag
{
   NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
   [userDefaults setObject:flag forKey:kSUBA_PLACES_COACHMARK_SEEN];
    [userDefaults synchronize];
}


+(NSString *)placesCoachMarkSeen
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:kSUBA_PLACES_COACHMARK_SEEN];
}


+(void)setNearbyCoachMark:(NSString *)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:flag forKey:kSUBA_NEARBY_COACHMARK_SEEN];
    [userDefaults synchronize];
}


+(NSString *)nearbyCoachMarkSeen
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:kSUBA_NEARBY_COACHMARK_SEEN];
}


+(void)setMyStreamCoachMark:(NSString *)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:flag forKey:kSUBA_MY_STREAM_COACHMARK_SEEN];
    [userDefaults synchronize];
}


+(NSString *)myStreamsCoachMarkSeen
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:kSUBA_MY_STREAM_COACHMARK_SEEN];
}


+(void)setCreateSpotCoachMark:(NSString *)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:flag forKey:kSUBA_CREATE_SPOT_COACHMARK_SEEN];
    [userDefaults synchronize];
}

+(NSString *)createSpotCoachMarkSeen
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:kSUBA_CREATE_SPOT_COACHMARK_SEEN];
}


+(void)setExploreCoachMark:(NSString *)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:flag forKey:kSUBA_EXPLORE_COACHMARK_SEEN];
    [userDefaults synchronize];
}


+(NSString *)exploreCoachMarkSeen
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:kSUBA_EXPLORE_COACHMARK_SEEN]; 
}


+(void)setWatchLocation:(NSString *)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:flag forKey:kSUBA_WATCH_LOCATION_COACHMARK_SEEN];
    [userDefaults synchronize];
}

+ (NSString *)watchLocationCoachMarkSeen
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:kSUBA_WATCH_LOCATION_COACHMARK_SEEN]; 
}

+ (void)setShareStreamCoachMark:(NSString *)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:flag forKey:kSUBA_SHARE_STREAM_COACHMARK_SEEN];
    [userDefaults synchronize];
}

+ (NSString *)shareStreamCoachMarkSeen
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:kSUBA_SHARE_STREAM_COACHMARK_SEEN];
}


+(BOOL)showFirstTimeView
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:SHOW_FIRST_TIME_VIEW]; 
}

+(void)setShowFirstTimeView:(BOOL)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:flag forKey:SHOW_FIRST_TIME_VIEW];
    [userDefaults synchronize];
}


+(NSDictionary *)inviteCodeDetails
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:ACTIVE_SPOT_CODE];
}

+(void)saveInviteCodeDetails:(NSDictionary *)code{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:code forKey:ACTIVE_SPOT_CODE];
    [userDefaults synchronize];
}

+ (NSString *)userSession
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:SESSION];
}


+ (void)setUserSession:(NSString *)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:flag forKey:SESSION];
    [userDefaults synchronize];
}


+(NSInteger)appSessions
{
   NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
   NSNumber *numSessions = [userDefaults valueForKey:NUMBER_OF_APP_SESSIONS];
    
   return [numSessions integerValue];
}


+(void)increaseAppSessions
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *appSessions = (NSNumber *)[userDefaults valueForKey:NUMBER_OF_APP_SESSIONS];
    NSInteger sessions = [appSessions integerValue];
    sessions = sessions + 1;
    [userDefaults setObject:[NSNumber numberWithInteger:sessions] forKey:NUMBER_OF_APP_SESSIONS];
    [self userHasInvited:@"NO"];
    [userDefaults synchronize];
}


+(NSString *)userStatus
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:kSUBA_USER_STATUS];
}

+(void)setUserStatus:(NSString *)status
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:status forKey:kSUBA_USER_STATUS];
    [userDefaults synchronize];
}


+(NSString *)hasUserInvited
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:USER_HAS_INVITED];
}

+(void)userHasInvited:(NSString *)flag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:flag forKey:USER_HAS_INVITED];
    [userDefaults synchronize];
}


+ (NSDictionary *)userPreferences{
     NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userPrefs = @{API_TOKEN : [userDefaults valueForKey:API_TOKEN],
                                EMAIL : [userDefaults valueForKey:EMAIL],
                                FIRST_NAME : [userDefaults valueForKey:FIRST_NAME],
                                LAST_NAME : [userDefaults valueForKey:LAST_NAME],
                                USER_NAME : [userDefaults valueForKey:USER_NAME],
                                PROFILE_PHOTO_URL : [userDefaults valueForKey:PROFILE_PHOTO_URL],
                                FACEBOOK_ID : [userDefaults valueForKey:FACEBOOK_ID],
                                SESSION : [userDefaults valueForKey:SESSION],
                                NUMBER_OF_ALBUMS : [userDefaults valueForKey:NUMBER_OF_ALBUMS]
                                };
    return userPrefs;    
}

#pragma mark - API calls
+ (void)createUserAccount:(NSDictionary *)user WithType:(NSString *)type completion:(GeneralCompletion)completionBlock{
    
    if ([type isEqualToString:FACEBOOK_LOGIN]){
        
        //Do Facebook Login
        
        [[SubaAPIClient sharedInstance]
         POST:@"authenticate"
         parameters:@{
                      @"id" : user[@"id"],
                      FIRST_NAME : user[FIRST_NAME],
                      LAST_NAME : user[LAST_NAME],
                      USER_NAME: user[USER_NAME],
                      EMAIL : user[EMAIL],
                      PASSWORD : user[PASSWORD],
                      @"profilePhoto" : user[PROFILE_PHOTO_URL],
                      @"fbLogin" : type
                }
         
         success:^(NSURLSessionDataTask __unused *task,id responseObject) {
             //DLog(@"This is straight from the server\n%@",responseObject);
             if ([responseObject[STATUS] isEqualToString:ALRIGHT]){
                 
                 [Flurry logEvent:@"Facebook_SignUp"];
                 [self savePreferences:responseObject];
                 
                 [self setFacebookID:user[@"id"]];
                 [self setProfilePhotoURL:user[PROFILE_PHOTO_URL]];
                 [self setFacebookLogin:@"YES"];
                 //[self setShowFirstTimeView:YES];
                 [self setUserStatus:kSUBA_USER_STATUS_CONFIRMED];
                 completionBlock(responseObject,nil);
             }
             
         }
         failure:^(NSURLSessionDataTask *task, NSError *error) {
             DLog(@"Something went wrong");
             
             completionBlock(nil,error);
         }];
    }else{
        
        // Do Native Sign Up
        [[SubaAPIClient sharedInstance]
         POST:@"signUp"
         parameters:user
         success:^(NSURLSessionDataTask __unused *task,id responseObject) {
             if ([responseObject[STATUS] isEqualToString:ALRIGHT]){
                 [AppHelper savePreferences:responseObject];
                 [self setFacebookLogin:@"NO"];
                 [self setShowFirstTimeView:YES];
                 [self setUserStatus:kSUBA_USER_STATUS_CONFIRMED];
                 completionBlock(responseObject,nil);
             }
         }
         failure:^(NSURLSessionDataTask *task, NSError *error) {
             completionBlock(nil,error);
         }];
    }
    
}

+(void)checkUserName:(NSString *)userName completionBlock:(UserNameCheckerCompletion)completionBlock{
    [[SubaAPIClient sharedInstance] GET:@"user/checkUserName" parameters:@{@"userName": userName} success:^(NSURLSessionDataTask *task, id responseObject){
        completionBlock(responseObject,nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completionBlock(nil,error);
    }];

}


+(void)loginUserWithEmailOrUserName:(NSString *)emailOrUserName AndPassword:(NSString *)password completionBlock:(UserLoggedInCompletion)completionBlock{
    
     [[SubaAPIClient sharedInstance]
            POST:@"login"
      parameters:@{
            EMAIL: emailOrUserName,
            PASSWORD : password
       } success:^(NSURLSessionDataTask *task, id responseObject) {
            DLog(@"Response - %@",responseObject);
           //[self setUserSession:@"login"];
           completionBlock(responseObject,nil);
           

       } failure:^(NSURLSessionDataTask *task, NSError *error) {
           DLog(@"Error - %@",error);
                completionBlock(nil,error);
        }];
}




#pragma mark - Convenience Methods
+(void)showAlert:(NSString *)title message:(NSString *)message buttons:(NSArray *)alertButtons delegate:(UIViewController *)delegate
{

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:alertButtons[0] otherButtonTitles:nil];
    
    [alert show];
}

+(CLLocationManager *)checkForLocation:(CLLocationManager *)locationManager delegate:(id)vc
{
    //BOOL locationEnabled = NO;
    if ([CLLocationManager locationServicesEnabled]){
        
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = vc;
       
    }else{
        
       [self showAlert:@"Location Services Disabled"
               message:@"Location services is disabled for this app. Please enable location services to see nearby spots" buttons:@[@"OK"] delegate:nil];
        
    }
    
    return locationManager;
}

+(void)showLoadingDataView:(UIView *)view indicator:(id)indicator flag:(BOOL)flag
{
    view.hidden = !flag;
    if (flag == YES) {
        [indicator startAnimating];
    }else [indicator stopAnimating]; 
}


+(void)showNotificationWithMessage:(NSString *)msg type:(NSString *)type inViewController:(UIViewController *)vc completionBlock:(NotificationCompletion)completion
{
    UIColor *tintColor = [UIColor colorWithRed:217/255.0 green:0.000 blue:7/255.0 alpha:1];
    
    if ([type isEqualToString:kSUBANOTIFICATION_SUCCESS]){
        tintColor = [UIColor colorWithRed:0.00 green:0.8 blue:0.2 alpha:1];
    }
    
    /*CSNotificationView *note = [[CSNotificationView alloc] initWithParentViewController:vc];
    note.showingActivity = YES;
    note.image = nil;
    note.tintColor = [UIColor colorWithRed:0.8 green:0.000 blue:0.2 alpha:1];
    
    if ([type isEqualToString:kSUBANOTIFICATION_SUCCESS]){
        note.tintColor = [UIColor colorWithRed:0.00 green:0.8 blue:0.2 alpha:1];
    }
    [note setVisible:YES animated:YES completion:nil];
    
    [note dismissWithStyle:CSNotificationViewStyleError message:msg
                  duration:kCSNotificationViewDefaultShowDuration animated:YES];*/

    
    [CSNotificationView showInViewController:vc
     tintColor: tintColor
     image:nil
     message:msg
     duration:3.5f];

}



+(void)showLikeImage:(UIImageView *)imgView imageNamed:(NSString *)imageName
{
    
    imgView.image = [UIImage imageNamed:imageName];
    
    
    [UIView animateWithDuration:1.0 animations:^{
        
        imgView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            
            imgView.alpha = 0;
        }];
    }];
}




#pragma mark - General Helpers
+(void)makeInitialPlaceholderViewWithSize:(NSInteger)labelSize view:(UIView *)contextView name:(NSString *)person
{
    [[contextView subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGRect frame = CGRectZero;
    NSString *initials = [[self initialStringForPersonString:person] uppercaseString];
    int numberOfCharacters = initials.length;
    
    if (numberOfCharacters == 1){
        
        frame = CGRectMake(contextView.bounds.origin.x+(contextView.bounds.size.width/2)-5, contextView.bounds.origin.y, contextView.bounds.size.width, contextView.bounds.size.height);
    }else if (numberOfCharacters == 2){
        
        frame = CGRectMake(contextView.bounds.origin.x+(contextView.bounds.size.width/2)-10, contextView.bounds.origin.y, contextView.bounds.size.width, contextView.bounds.size.height);
    }

    
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:labelSize];
    
    UILabel *initialsLabel = [[UILabel alloc] initWithFrame:contextView.bounds];
    initialsLabel.textColor = [UIColor whiteColor];
    initialsLabel.font = font;
    initialsLabel.text = [[self initialStringForPersonString:person] uppercaseString];
    contextView.backgroundColor = [self circleColor];
    
    [contextView addSubview:initialsLabel];
}

+(UIColor *)circleColor
{
   return [UIColor colorWithHue:arc4random() % 256 / 256.0 saturation:0.7 brightness:0.8 alpha:1.0];
}

+(NSString *)initialStringForPersonString:(NSString *)personString
{
    NSString *initials = nil;
    NSArray *comps = [personString componentsSeparatedByString:kEMPTY_STRING_WITH_SPACE];
    NSMutableArray *mutableComps = [NSMutableArray arrayWithArray:comps];
    
    for (NSString *component in mutableComps) {
        if ([component isEqualToString:kEMPTY_STRING_WITH_SPACE]) {
            [mutableComps removeObject:component];
        }
    }
    
    if ([mutableComps count] >= 2) {
        NSString *firstName = mutableComps[0];
        NSString *lastName = mutableComps[1];
        
        initials =  [NSString stringWithFormat:@"%@%@", [firstName substringToIndex:1], [lastName substringToIndex:1]];
    } else if ([mutableComps count]) {
        NSString *name = mutableComps[0];
        initials =  [name substringToIndex:1];
    }
    
    return initials;
}


+ (void)fillView:(UIView *)view WithImage:(NSString *)imageURL
{
    [[view subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGRect frame = CGRectMake(view.bounds.origin.x, view.bounds.origin.y, view.bounds.size.width, view.bounds.size.height);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [imageView setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    
    view.backgroundColor = [UIColor clearColor];
    
    [view addSubview:imageView];
    
    

}


+ (NSInteger)numberOfPhotoStreamEntries
{
   NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
   NSString *numberOfStreamEntries = [userDefaults valueForKey:kSUBA_USER_NUMBER_OF_PHOTO_STREAM_ENTRIES];
    return [numberOfStreamEntries integerValue];
}


+ (void)increasePhotoStreamEntries
{
    // Get the current number of stream entries
    NSInteger numberOfStreamEntries = [self numberOfPhotoStreamEntries] + 1;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:[NSString stringWithFormat:@"%i",numberOfStreamEntries] forKey:kSUBA_USER_NUMBER_OF_PHOTO_STREAM_ENTRIES];
    
    [userDefaults synchronize];
}


+(void)openFBSession:(GeneralCompletion)completion
{
    [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email",@"user_birthday"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error){
        
        
        DLog(@"Opening FB Session with token - %@\nSession - %@",session.accessTokenData.expirationDate,[session debugDescription]);
        
        if (error) {
            DLog(@"Facebook Error - %@\nFriendly Error - %@",[error debugDescription],error.localizedDescription);
        }else if (session.isOpen){
            [AppHelper setFacebookSession:@"YES"];
           
            
            
            NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"first_name,last_name,username,email,picture.type(large)" forKey:@"fields"];
            
            [FBRequestConnection startWithGraphPath:@"me" parameters:parameters HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                DLog(@"FB Auth Result - %@\nError - %@",result,error);
                if (!error) {
                    NSDictionary<FBGraphUser> *user = result;
                    
                    NSString *userEmail = [user valueForKey:@"email"];
                    if (userEmail == NULL) {
                        [AppHelper showAlert:@"Facebook Error"
                                     message:@"There was an issue retrieving your facebook email address."
                                     buttons:@[@"OK"] delegate:nil];
                        
                        /*[AppHelper showLoadingDataView:self.connectingToFacebookView indicator:self.connectingToFacebookIndicator flag:NO];
                         self.connectingToFacebookView.alpha = 0;*/
                        
                    }else{
                        NSString *pictureURL = [[[result valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
                        
                        [AppHelper setProfilePhotoURL:pictureURL];
                        
                        DLog(@"ID - %@\nfirst_name - %@\nLast_name - %@\nEmail - %@\nUsername - %@\nPicture - %@\n",user.id,user.first_name,user.last_name,[user valueForKey:@"email"],user.username,pictureURL);
                        
                        
                        
                        NSDictionary *fbSignUpDetails = @{
                                                          @"id" :user.id,
                                                          FIRST_NAME: user.first_name,
                                                          LAST_NAME : user.last_name,
                                                          EMAIL :  userEmail,
                                                          USER_NAME : user.username,
                                                          @"pass" : @"",
                                                          PROFILE_PHOTO_URL : pictureURL
                                                          };
                        
                        
                        [AppHelper createUserAccount:fbSignUpDetails WithType:FACEBOOK_LOGIN completion:^(id response, NSError *error) {
                            if (!error){
                                DLog(@"Response - %@",result);
                                completion(response,nil);
                            }else{
                                DLog(@"Error - %@",error);
                                [AppHelper showAlert:@"Authentication Error"
                                             message:@"There was a problem authentication you on our servers. Please wait a minute and try again"
                                             buttons:@[@"OK"]
                                            delegate:nil];
                                
                            }
                        }];
                    }
                }
            }];
        }
        
    }];
    

}

@end







