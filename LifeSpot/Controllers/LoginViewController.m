//
//  LoginViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/6/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "LoginViewController.h"
#import "User.h"

@interface LoginViewController ()<UITextFieldDelegate>
@property (copy,nonatomic) NSString *userName;
@property (copy,nonatomic) NSString *pass;

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginSpinner;
@property (strong, nonatomic) IBOutlet UIScrollView *loginScrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *fbLoginIndicator;


@property (weak, nonatomic) IBOutlet UIButton *facebookLoginBtn;
- (IBAction)doFacebookLogin:(UIButton *)sender;

- (void)loginUserWithEmail:(NSString *)email AndPassword:(NSString *)password;
- (void)openFBSession;
@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.loginBtn.enabled = NO;
    self.navigationController.navigationBarHidden = YES;
	// Do any additional setup after loading the view.
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginAction:(UIButton *)sender {
    
    self.userName = self.userNameField.text;
    self.pass = self.pwdField.text;
    
    [self loginUserWithEmail:self.userName AndPassword:self.pass];
}




#pragma mark - API Calls
-(void)loginUserWithEmail:(NSString *)email AndPassword:(NSString *)password
{
    [self.loginSpinner startAnimating];
    
    [AppHelper loginUserWithEmailOrUserName:email
                                AndPassword:password
                            completionBlock:^(id results, NSError *error) {
                                DLog(@"Results - %@",results);
                                [self.loginSpinner stopAnimating];
                                
                                if (!error) {
                                    if ([results[STATUS] isEqualToString:ALRIGHT]) {
                                        //DLog(@"")
                                        [AppHelper savePreferences:results];
                                        [AppHelper setUserStatus:kSUBA_USER_STATUS_CONFIRMED];
                                        
                                        [Flurry logEvent:@"Login_Action"];
                                        [self performSegueWithIdentifier:@"Login_MainTabBar_Segue" sender:nil];
                                        
                                    }else{
                                        [AppHelper showAlert:results[STATUS] message:results[@"message"] buttons:@[@"I'll check again"] delegate:nil];
                                    }
                                }else{
                                    
                                    DLog(@"Error localizedDescription - %@\nError Description - %@\nError localizedFailureReason - %@",error.localizedDescription,error.userInfo,error.localizedFailureReason);
                                    
                                    [AppHelper showAlert:@"Login Failure" message:error.localizedDescription buttons:@[@"OK"] delegate:nil];
                                }
                            }];
}




#pragma mark - Textfield delegate method
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self.loginScrollView setContentOffset:CGPointMake(self.loginScrollView.frame.origin.x,50.0f)];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.userNameField && textField.text.length > 0) {
        [self.pwdField becomeFirstResponder];
    }else if (textField == self.userNameField && textField.text.length <= 0){
        [textField resignFirstResponder];
    }
    
    if (textField == self.pwdField) { // if we are in the password field
        
        if (![self.pwdField.text isEqualToString:@""] && ![self.userNameField.text isEqualToString:@""]){
            self.userName = self.userNameField.text;
            self.pass = self.pwdField.text;
            
            [self loginUserWithEmail:self.userName AndPassword:self.pass];
        }
    }
    return YES;
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField == self.pwdField) {
        if (![self.userNameField.text isEqualToString:@""] && ![self.pwdField.text isEqualToString:@""]) {
            self.loginBtn.enabled = YES;
        }
    }
    return YES;
}



/*#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    DLog(@"encode");
    
    self.userName = self.userNameField.text;
    [coder encodeObject:self.userName forKey:EmailOrUserNameKey];
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    DLog(@"decode");
    
    self.userName = [coder decodeObjectForKey:EmailOrUserNameKey];
    
}

-(void)applicationFinishedRestoringState
{
    // Inflate view from freezed state
    self.userNameField.text = self.userName;
}
*/

-(void)openFBSession
{
    [self.fbLoginIndicator startAnimating];
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
                        
                        //DLog(@"FB LOGIN UP DETAILS : %@",fbSignUpDetails);
                        
                        [AppHelper createUserAccount:fbSignUpDetails WithType:FACEBOOK_LOGIN completion:^(id results, NSError *error) {
                            [self.fbLoginIndicator stopAnimating];
                            //[AppHelper showLoadingDataView:self.connectingToFacebookView indicator:self.connectingToFacebookIndicator flag:NO];
                            //self.connectingToFacebookView.alpha = 0;
                            
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


- (IBAction)doFacebookLogin:(UIButton *)sender
{
   [self openFBSession];
}
@end
