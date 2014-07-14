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

@interface SubaTutorialController ()<CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UIView *connectingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *inviteCodeButton;


- (IBAction)unWindToHomeScreen:(UIStoryboardSegue *)segue;

- (IBAction)seeNearbyStreams:(UIButton *)sender;

//- (void)openFBSession;
- (void)checkLocation;
//- (IBAction)fbLoginAction:(id)sender;

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



-(IBAction)unWindToHomeScreen:(UIStoryboardSegue *)segue
{
    /*if ([segue.sourceViewController class] == [PhotoStreamViewController class]){
        DLog(@"We came from a photo stream");
        self.inviteCodeButton.hidden = YES;
        self.navigationController.navigationBarHidden = YES;
    }else{
        self.inviteCodeButton.hidden = NO;
        self.navigationController.navigationBarHidden = YES;
    }*/
}

- (IBAction)seeNearbyStreams:(UIButton *)sender
{
    [Flurry logEvent:@"See_Nearby_Streams"];
    [self checkLocation];
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
    }
}


#pragma mark - Facebook Login
/*- (void)openFBSession{
    //[self.fbLoginIndicator startAnimating];
    
    
    [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email",@"user_birthday"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error){
        
        
        DLog(@"Opening FB Session with token - %@\nSession - %@",session.accessTokenData.expirationDate,[session debugDescription]);
        
        if (error) {
            DLog(@"Facebook Error - %@\nFriendly Error - %@",[error debugDescription],error.localizedDescription);
        }else if (session.isOpen){
            [AppHelper setFacebookSession:@"YES"];
            //[self.fbLoginIndicator stopAnimating];
            
            
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
                        
                        [AppHelper showLoadingDataView:self.connectingToFacebookView indicator:self.connectingToFacebookIndicator flag:NO];
                        self.connectingToFacebookView.alpha = 0;
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
                    
                    
                    [AppHelper createUserAccount:fbSignUpDetails WithType:FACEBOOK_LOGIN completion:^(id results, NSError *error) {
                        
                        [AppHelper showLoadingDataView:self.connectingToFacebookView indicator:self.connectingToFacebookIndicator flag:NO];
                        self.connectingToFacebookView.alpha = 0;
                        
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

- (IBAction)fbLoginAction:(id)sender
{
    //DLog();
    self.connectingToFacebookView.alpha = 1;
    [AppHelper showLoadingDataView:self.connectingToFacebookView indicator:self.connectingToFacebookIndicator flag:YES];
    [self openFBSession];
}*/






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
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined ||
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized){
            
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
            [locationManager startUpdatingLocation];
            
            // Go to the mainTabBar
            //UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            
            
        }else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
            
            [AppHelper showAlert:@"Location Error" message:[NSString stringWithFormat:@"%@\n%@",@"Suba does not have access to your location.",@"In order to see streams nearby, go to Settings->Privacy->Location Services and enable location for Suba" ] buttons:@[@"OK"] delegate:nil];
            
        }
    }else{
        [AppHelper showAlert:@"Location Off"
                     message:@"Looks like location is off on your device."
                     buttons:@[@"OK"] delegate:nil];
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
        /*[AppHelper showAlert:@"Location Error" message:[NSString stringWithFormat:@"%@\n%@",@"Suba does not have access to your location.",@"In order to see streams nearby, go to Settings->Privacy->Location Services and enable location for Suba" ] buttons:@[@"OK"] delegate:nil];*/
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









@end
