//
//  SubaTutorialController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 2/2/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "SubaTutorialController.h"
#import "TermsViewController.h"
#import "EnterInviteCodeViewController.h"
#import "SignUpViewController.h"
#import "PhotoStreamViewController.h"
#import "User.h"
#import "InviteView.h"
#import <GoogleOpenSource/GoogleOpenSource.h>

@interface SubaTutorialController ()<CLLocationManagerDelegate,UIActionSheetDelegate>
{
    GPPSignIn *googleSignIn;
}

@property (weak, nonatomic) IBOutlet UIView *connectingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *inviteCodeButton;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;

@property (retain, nonatomic) IBOutlet UIButton *signInWithGoogleButton;


- (IBAction)unWindToHomeScreen:(UIStoryboardSegue *)segue;

- (IBAction)seeNearbyStreams:(UIButton *)sender;
- (IBAction)loginWithGoogle:(UIButton *)sender;

//- (void)openFBSession;
- (void)checkLocation;
- (void)prepareGoogleSignIn;
//- (void)handleInviteToStream:(NSNotification *)notification;
@end

@implementation SubaTutorialController
static CLLocationManager *locationManager;

-(void)viewDidLoad{
    [super viewDidLoad];
   self.navigationController.navigationBarHidden = YES;
    
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    DLog();
    //if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
    //}
}



-(IBAction)unWindToHomeScreen:(UIStoryboardSegue *)segue{}

- (IBAction)seeNearbyStreams:(UIButton *)sender
{
    [Flurry logEvent:@"See_Nearby_Streams"];
    [self checkLocation];
}

- (IBAction)loginWithGoogle:(UIButton *)sender
{
    sender.enabled = NO;
    [self.activityIndicator startAnimating];
    [self prepareGoogleSignIn];

}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AgreeTermsSegue"]) {
        TermsViewController *termsVC = segue.destinationViewController;
        if ([sender integerValue] == 5) {
            //DLog(@"Want to see terms");
            termsVC.urlToLoad = [NSURL URLWithString:@"http://www.subaapp.com/terms.html"];
            termsVC.navigationItem.title = @"Terms";
        }else if ([sender integerValue] == 10) {
            //DLog(@"Want to see privacy");
            termsVC.urlToLoad = [NSURL URLWithString:@"http://www.subaapp.com/privacy.html"];
            termsVC.navigationItem.title = @"Privacy";
        }
    }else if([segue.identifier isEqualToString:@"HomeScreenToPhotoStreamSegue"]){
        if ([AppHelper inviteCodeDetails]){
            DLog(@"invite code details - %@",[AppHelper inviteCodeDetails]);
            EnterInviteCodeViewController *enVC = segue.destinationViewController;
            enVC.inviteCode = (NSString *)sender[@"streamId"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACTIVE_SPOT_CODE];
        }
    }else if ([segue.identifier isEqualToString:@"LogInScreen"]){
        if ([self.view viewWithTag:300]) {
            // There's a pop showing
            UIView *popUpView = [self.view viewWithTag:300];
            [popUpView removeFromSuperview];
        }
    }
}


#pragma mark - Facebook Login
- (void)openFBSession{
    //[self.fbLoginIndicator startAnimating];
    
    
    [FBSession openActiveSessionWithReadPermissions:@[@"public_profile",@"email"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error){
        
        
        DLog(@"Opening FB Session with token - %@\nSession - %@",session.accessTokenData.expirationDate,[session debugDescription]);
        
        if (error) {
            DLog(@"Facebook Error - %@\nFriendly Error - %@",[error debugDescription],error.localizedDescription);
        }else if (session.isOpen){
            [AppHelper setFacebookSession:@"YES"];
            //[self.fbLoginIndicator stopAnimating];
            
            
            NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"first_name,last_name,email,picture.type(large)" forKey:@"fields"];
            
            [FBRequestConnection startWithGraphPath:@"me" parameters:parameters HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                DLog(@"FB Auth Result - %@\nError - %@",result,error);
                if (!error) {
                    NSDictionary<FBGraphUser> *user = result;
                    
                    NSString *userEmail = [user valueForKey:@"email"];
                    if (userEmail == NULL) {
                        [AppHelper showAlert:@"Facebook Error"
                                     message:@"There was an issue retrieving your facebook email address."
                                     buttons:@[@"OK"] delegate:nil];
                        
                        //[AppHelper showLoadingDataView:self.connectingToFacebookView indicator:self.connectingToFacebookIndicator flag:NO];
                        [self.activityIndicator stopAnimating];
                    }else{
                    NSString *pictureURL = [[[result valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
                    
                    [AppHelper setProfilePhotoURL:pictureURL];
                    
                    DLog(@"ID - %@\nfirst_name - %@\nLast_name - %@\nEmail - %@\nPicture - %@\n",user.objectID,user.first_name,user.last_name,[user valueForKey:@"email"],pictureURL);
                    
                    
                    
                    NSDictionary *fbSignUpDetails = @{
                                                      @"id" :user.objectID,
                                                      FIRST_NAME: user.first_name,
                                                      LAST_NAME : user.last_name,
                                                      EMAIL :  userEmail,
                                                      USER_NAME : userEmail,
                                                      @"pass" : @"",
                                                      PROFILE_PHOTO_URL : pictureURL
                                                      };
                    
                    
                    [AppHelper createUserAccount:fbSignUpDetails WithType:FACEBOOK_LOGIN completion:^(id results, NSError *error) {
                        
                        //[AppHelper showLoadingDataView:self.connectingToFacebookView indicator:self.connectingToFacebookIndicator flag:NO];
                        [self.activityIndicator stopAnimating];
                        self.facebookButton.enabled = YES;
                        
                        if (!error) {
                            //DLog(@"Response - %@",result);
                            if([AppHelper inviteCodeDetails]){
                            [self performSegueWithIdentifier:@"HomeScreenToPhotoStreamSegue" sender:[AppHelper inviteCodeDetails]];
                            }else{
                            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                            UIViewController *personalSpotsVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"MAINTAB_BAR"];
                            
                            [self presentViewController:personalSpotsVC animated:YES completion:nil];
                         }
                        }else{
                            DLog(@"Error - %@",error);
                            [AppHelper showAlert:@"Authentication Error"
                                         message:@"There was a problem authenticating you on our servers. Please wait a minute and try again"
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

- (IBAction)fbLoginAction:(UIButton *)sender
{
    sender.enabled = NO;
    [self.activityIndicator startAnimating];
    [self openFBSession];
}






- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





#pragma mark - helper methods
-(void)checkLocation
{
    // Check whether Location is enabled for this device
    
    if ([CLLocationManager locationServicesEnabled]) {
        // If location has been enabled for Suba
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized){
            
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
            if (IS_OS_7_OR_BEFORE) {
                DLog(@"IOS 7");
                [locationManager startUpdatingLocation];
            }else if(IS_OS_8_OR_LATER){
                [locationManager requestWhenInUseAuthorization];
            }
            
            // Go to the mainTabBar
            //UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            
            
        }else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
            
            [AppHelper showAlert:@"No access to location"
                         message:[NSString stringWithFormat:@"%@\n%@",@"Suba could not determine your location.",@"In order to see streams created nearby, go to Settings->Privacy->Location Services and enable location for Suba"]
                         buttons:@[@"OK"] delegate:nil];
            
        }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted){
            [AppHelper showAlert:@"No access to location"
                         message:[NSString stringWithFormat:@"%@\n%@",@"Suba could not determine your location.",@"In order to see streams created nearby, go to Settings->Privacy->Location Services and enable location for Suba"]
                         buttons:@[@"OK"] delegate:nil];

        }else{
            [AppHelper showAlert:@"No access to location"
                         message:[NSString stringWithFormat:@"%@\n%@",@"Suba could not determine your location.",@"In order to see streams created nearby, go to Settings->Privacy->Location Services and enable location for Suba"]
                         buttons:@[@"OK"] delegate:nil];
        }
        
    }
}



#pragma mark - Location Manager Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //[locationManager stopUpdatingLocation];
}


-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([error code] == kCLErrorDenied) {
        //you had denied
        [AppHelper showAlert:@"Location Error"
                     message:[NSString stringWithFormat:@"%@\n%@",@"Suba could not retrieve your current location.",@"In order to see streams created nearby, go to Settings->Privacy->Location Services and enable location for Suba" ]
                     buttons:@[@"OK"] delegate:nil];
    }
    
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied){
        DLog(@"We've been denied access to location so show header view");
        
    }else if (status == kCLAuthorizationStatusAuthorized){
        DLog(@"creating guest account");
        
        //[AppHelper showLoadingDataView:self.connectingView indicator:self.activityIndicator flag:YES];
        [self.activityIndicator startAnimating];
        //UIViewController *personalSpotsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MAINTAB_BAR"];
        //[self presentViewController:personalSpotsVC animated:YES completion:nil];

        // Creating guest account and after go to main screen
        if ([[AppHelper userID] isEqualToString:kSUBA_GUEST_USER_ID]){
            DLog(@"User is -%@",[AppHelper userID]);
            [User createGuestAccount:^(id results, NSError *error) {
               // [AppHelper showLoadingDataView:self.connectingView indicator:self.activityIndicator flag:NO];
                [self.activityIndicator stopAnimating];
                if (!error) {
                    if ([results[STATUS] isEqualToString:ALRIGHT]) {
                        DLog(@"results - %@",results);
                        [AppHelper savePreferences:results];
                        [AppHelper setFacebookLogin:@"NO"];
                        [AppHelper setUserStatus:kSUBA_USER_STATUS_ANONYMOUS];
                        [self performSegueWithIdentifier:@"SeeNearby_MainTabBar_Segue" sender:nil];
                        
                        //[self presentViewController:personalSpotsVC animated:YES completion:nil];
                    }else{
                        DLog(@"Error - %@",results);
                    }
                }
            }];
        }else{
            [self performSegueWithIdentifier:@"SeeNearby_MainTabBar_Segue" sender:nil];
            //[self presentViewController:personalSpotsVC animated:YES completion:nil];
        }
    }
}

-(void)showSignUpOptions
{
    UIActionSheet *signUpOptions = [[UIActionSheet alloc] initWithTitle:@"Create an account" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Connect with Facebook",@"Use email instead", nil];
    
    [signUpOptions showInView:self.view];
}


#pragma mark - sign up options action sheet
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    
    if (buttonIndex == 0){
        // User selected facebook
        [self.activityIndicator startAnimating];
        if ([self.view viewWithTag:300]) {
            // There's a pop showing
            UIView *popUpView = [self.view viewWithTag:300];
            [popUpView removeFromSuperview];
        }
        [self openFBSession];
    }else if (buttonIndex == 1){
       // User wants to do manual sign up
        if ([self.view viewWithTag:300]) {
            // There's a pop showing
            UIView *popUpView = [self.view viewWithTag:300];
            [popUpView removeFromSuperview];
        }
        [self performSegueWithIdentifier:@"SignUpScreen" sender:nil];
    }
    
    
}


#pragma mark - Google Plus sign in
-(void)prepareGoogleSignIn
{
    googleSignIn = [GPPSignIn sharedInstance];
    //googleSign.shouldFetchGooglePlusUser = YES;
    googleSignIn.shouldFetchGoogleUserEmail = YES;
    
    googleSignIn.clientID = kSUBA_GOOGLEPLUS_CLIENT_ID;
    
    //googleSign.scopes = @[ kGTLAuthScopePlusLogin ];  // "https://www.googleapis.com/auth/plus.login" scope
    googleSignIn.scopes = @[ @"profile" ];            // "profile" scope
    
    // Optional: declare signIn.actions, see "app activities"
    googleSignIn.delegate = self;
    
    DLog(@"Authenticating user");
    [googleSignIn authenticate];
}


- (void)fetchGoogleUserInfo:(GTMOAuth2Authentication *)auth
{
    GTLServicePlus* plusService = [[GTLServicePlus alloc] init];
    plusService.retryEnabled = YES;
    
    [plusService setAuthorizer:auth];
    GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];

    [plusService executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLPlusPerson *person, NSError *error) {
        [self.activityIndicator stopAnimating];
        self.signInWithGoogleButton.enabled = NO;
        if (error) {
            [AppHelper showAlert:@"Google Login" message:@"We encountered problems authenticating with Google. Please try again?" buttons:@[@"OK"] delegate:nil];
        }else{
            // We have the user info
            
            NSString *googleUserEmail = googleSignIn.authentication.userEmail;
            NSString *googleUserId = person.identifier;
            NSString *googleUserFirstName = person.name.givenName;
            NSString *googleUserLastName = person.name.familyName;
            GTLPlusPersonImage *googleUserImage = person.image;
            
            //NSURL *imgURL = [NSURL URLWithString:googleUserImage.url];
            
            
            
            NSString *largeImgURL = [googleUserImage.url
                                  stringByReplacingOccurrencesOfString:@"sz=50" withString:@"sz=100"];
            
            [AppHelper setProfilePhotoURL:largeImgURL];
           //DLog(@"IMG parameters: %@\nNew image: %@",imgURL.pathComponents,largeImg);
            
            NSString *userName = person.displayName;
            
            NSDictionary *googleSignUpDetails = @{
                                                  @"id" :googleUserId,
                                                  FIRST_NAME: googleUserFirstName,
                                                  LAST_NAME : googleUserLastName,
                                                  EMAIL :  googleUserEmail,
                                                  USER_NAME : userName,
                                                  @"pass" : @"",
                                                  PROFILE_PHOTO_URL : largeImgURL
                                            };
            
            
            [AppHelper createUserAccount:googleSignUpDetails
                                WithType:GOOGLE_LOGIN completion:^(id results, NSError *error){
                                    
                self.signInWithGoogleButton.enabled = YES;
                [self.activityIndicator stopAnimating];
                
                if (!error) {
                    //DLog(@"Response - %@",result);
                    if([AppHelper inviteCodeDetails]){
                        [self performSegueWithIdentifier:@"HomeScreenToPhotoStreamSegue" sender:[AppHelper inviteCodeDetails]];
                    }else{
                        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                        UIViewController *personalSpotsVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"MAINTAB_BAR"];
                        
                        [self presentViewController:personalSpotsVC animated:YES completion:nil];
                    }
                }else{
                    DLog(@"Error - %@",error);
                    [AppHelper showAlert:@"Authentication Error"
                                 message:@"There was a problem authenticating you on our servers. Please wait a minute and try again"
                                 buttons:@[@"OK"]
                                delegate:nil];
                    
                }

            }];
            
        }
    }];

}


- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth
                   error: (NSError *) error {
    
    DLog(@"Received error %@ and auth object %@",error, [auth.parameters debugDescription]);
    
    if (!error) {
        [self fetchGoogleUserInfo:auth];
    }else{
        [AppHelper showAlert:@"Google Login Error" message:@"We encountered problems authenticating with Google. Please try again?" buttons:@[@"Try Again"] delegate:nil];
    }
}




-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}











@end
