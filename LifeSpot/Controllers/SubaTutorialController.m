//
//  SubaTutorialController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 2/2/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "SubaTutorialController.h"
#import "TermsViewController.h"

@interface SubaTutorialController ()
@property (weak, nonatomic) IBOutlet UIView *connectingToFacebookView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *connectingToFacebookIndicator;

- (void)openFBSession;

- (IBAction)fbLoginAction:(id)sender;
@end

@implementation SubaTutorialController

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
    }
}


#pragma mark - Facebook Login
- (void)openFBSession{
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
                            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                            UIViewController *personalSpotsVC = [mainStoryboard instantiateViewControllerWithIdentifier:@"MAINTAB_BAR"];
                            
                            [self presentViewController:personalSpotsVC animated:YES completion:nil];
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
}






- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
