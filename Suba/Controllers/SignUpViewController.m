//
//  SignUpViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/6/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "SignUpViewController.h"
#import "PhotoStreamViewController.h"
#import "TermsViewController.h"

@interface SignUpViewController ()<UITextFieldDelegate>

@property (copy,nonatomic) NSString *firstName;
@property (copy,nonatomic) NSString *lastName;
@property (copy,nonatomic) NSString *userName;
@property (copy,nonatomic) NSString *email;
@property (copy,nonatomic) NSString *password;
@property (copy,nonatomic) NSString *confirmPassword;

@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *userNameCheckerIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *signUpActivityIndicator;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordField;


- (IBAction)signUp:(UIButton *)sender;

- (void)checkAllTextFields;
- (void)checkUserName:(NSString *)userName;
- (void)createUserAccount:(NSDictionary *)params;
//- (void)keyboardWillShowNotification:(NSNotification *)aNotification;
//- (void)keyboardWillHidesNotification:(NSNotification *)aNotification;

@end

@implementation SignUpViewController

bool isUserNameAvailable = NO;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.signUpButton.enabled = NO;
    
    /*[[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHidesNotification:) name:UIKeyboardWillHideNotification object:nil];*/
}

-(void)viewWillAppear:(BOOL)animated{
    //[self.firstNameField becomeFirstResponder];
    [super viewWillAppear:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)checkAllTextFields
{
    if (![self.confirmPasswordField.text isEqualToString:@""]) {
        
        if (![self.emailField.text isEqualToString:@""] && ![self.userNameField.text isEqualToString:@""]
            && ![self.firstNameField.text isEqualToString:@""] && ![self.lastNameField.text isEqualToString:@""]
            && ![self.passwordField.text isEqualToString:@""]){
            // Now all the fields are not empty
            
            //1. Let's first check whether the email is correct
            if ([AppHelper validateEmail:self.emailField.text]){
                // If the email is correct,begin to process everything else
                
                
                if ([self.userNameField.text isEqualToString:self.passwordField.text]){
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Yet to sign up" message:@"Your username and password appear to be the same" delegate:nil cancelButtonTitle:@"I'll check" otherButtonTitles:nil];
                    
                    [alertView show];
                }else{
                    
                    self.firstName = self.firstNameField.text;
                    self.lastName = self.lastNameField.text;
                    self.userName = self.userNameField.text;
                    self.email = self.emailField.text;
                    self.confirmPassword = self.confirmPasswordField.text;
                    self.password = self.passwordField.text;
                    
                    NSDictionary *params = @{
                                             @"firstName":self.firstName,
                                             @"lastName":self.lastName,
                                             @"email": self.email,
                                             @"pass":self.password,
                                             @"userName":self.userName,
                                             @"fbLogin" : NATIVE
                                             };
                    
                    [self createUserAccount:params]; // Sign the user up
                }
            }else{
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"Email check"
                                          message:@"We could not verfiy your email address format.Please check again"
                                          delegate:nil
                                          cancelButtonTitle:@"I'll check"
                                          otherButtonTitles:nil];
                
                [alertView show];
            }
        }
        
    }

}


- (IBAction)signUp:(UIButton *)sender {
    
    if (![self.confirmPasswordField.text isEqualToString:self.passwordField.text]) {
        [AppHelper showAlert:@"Oops!" message:@"Your passwords do not match" buttons:@[@"Will check again"] delegate:nil];
    }else{
    
    //Save these in a model
    self.firstName = self.firstNameField.text;
    self.lastName = self.lastNameField.text;
    self.email = self.emailField.text;
    
    self.userName = self.userNameField.text;
    self.password = self.passwordField.text;
    
    [self checkAllTextFields];
  }
}

- (IBAction)dismissKeypad:(id)sender{
    DLog();
    [self.firstNameField resignFirstResponder];
    [self.lastNameField resignFirstResponder];
    [self.emailField resignFirstResponder];
    [self.userNameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.confirmPasswordField resignFirstResponder];
    
    UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
    [scrollView setContentOffset:CGPointMake(0,0) animated:YES];
}



#pragma mark - UITextField Delegate Methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.firstNameField)[self.lastNameField becomeFirstResponder];
    if (textField == self.lastNameField)[self.userNameField becomeFirstResponder];
    if (textField == self.userNameField){
        UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
        [scrollView setContentOffset:CGPointMake(0, scrollView.frame.origin.y + textField.frame.size.height) animated:YES];
      [self.emailField becomeFirstResponder];
    }
    if (textField == self.emailField){
        UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
        [scrollView setContentOffset:CGPointMake(0, scrollView.frame.origin.y + self.emailField.frame.size.height) animated:YES];
        [self.passwordField becomeFirstResponder];
    }
    if (textField == self.passwordField){
        UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
        [scrollView setContentOffset:CGPointMake(0, scrollView.frame.origin.y + self.passwordField.frame.size.height+50) animated:YES];
        
        [self.confirmPasswordField becomeFirstResponder];
    }
    
    if (textField == self.confirmPasswordField && ![textField.text isEqualToString:@""]) {
        
        /*if (![self.emailField.text isEqualToString:@""] && ![self.userNameField.text isEqualToString:@""]
             && ![self.firstNameField.text isEqualToString:@""] && ![self.lastNameField.text isEqualToString:@""]
            && ![self.passwordField.text isEqualToString:@""]){
            // Now all the fields are not empty
            
            //1. Let's first check whether the email is correct
            if ([AppHelper validateEmail:self.emailField.text]){
                // If the email is correct,begin to process everything else
                
                
                if ([self.userNameField.text isEqualToString:self.passwordField.text]){
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Yet to sign up" message:@"Your username and password appear to be the same" delegate:nil cancelButtonTitle:@"I'll check" otherButtonTitles:nil];
                    
                    [alertView show];
                }else{
                    
                    
                    self.email = self.emailField.text;
                    self.userName = self.userNameField.text;
                    self.password = self.passwordField.text;
                    
                    NSDictionary *params = @{
                                             @"email": self.email,
                                             @"pass":self.password,
                                             @"userName":self.userName,
                                             @"fbLogin" : NATIVE
                                             };
                    
                    [self createUserAccount:params]; // Sign the user up
                }
            }else{
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"Email check"
                                          message:@"We could not verfiy your email address format.Please check again"
                                          delegate:nil
                                          cancelButtonTitle:@"I'll check"
                                          otherButtonTitles:nil];
                
                [alertView show];
            }
        }*/
        
        DLog();
        [self.firstNameField resignFirstResponder];
        [self.lastNameField resignFirstResponder];
        [self.emailField resignFirstResponder];
        [self.userNameField resignFirstResponder];
        [self.passwordField resignFirstResponder];
        [self.confirmPasswordField resignFirstResponder];
        
        UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
        [scrollView setContentOffset:CGPointMake(0,0) animated:YES];

        
        
    }
    return YES;
}



-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.userNameField && ![textField.text isEqualToString:@""]) {
        self.userName = self.userNameField.text;
        [self checkUserName:self.userName];
    }
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    
    if (textField == self.confirmPasswordField && ![self.confirmPasswordField.text isEqualToString:@""]){
        if (![self.firstNameField.text isEqualToString:@""] && ![self.lastNameField.text isEqualToString:@""]
            && ![self.emailField.text isEqualToString:@""] && ![self.userNameField.text isEqualToString:@""]
            && ![self.passwordField.text isEqualToString:@""]){
            
            self.signUpButton.enabled = YES;
        }
    }
    return YES;
}



#pragma mark - API Calls
-(void)checkUserName:(NSString *)userName{
    [self.userNameCheckerIndicator startAnimating];
    
    [AppHelper checkUserName:userName
                completionBlock:^(id results, NSError *error) {
                    [self.userNameCheckerIndicator stopAnimating];
        if (!error){
            
            
            if ([results[STATUS] isEqualToString:ALRIGHT]){
                isUserNameAvailable = YES;
                
            }else{
                [AppHelper
                 showNotificationWithMessage:@"This username has already been taken.Please chose a different one"
                                        type:kSUBANOTIFICATION_ERROR
                            inViewController:self
                             completionBlock:nil];
            }
        }else{
            DLog(@"Error - %@",error);
        }
    }];
}


-(void)createUserAccount:(NSDictionary *)params{
    //DLog(@"UseName Available - %i",isUserNameAvailable);
    if (isUserNameAvailable == NO) {
        [self checkUserName:self.userNameField.text];
    }else{
        [self.signUpActivityIndicator startAnimating];
        
    [AppHelper createUserAccount:params
                           WithType:NATIVE_LOGIN
                         completion:^(id results, NSError *error){
            [self.signUpActivityIndicator stopAnimating];
        if (!error){
            NSMutableDictionary *analyticsParams = [NSMutableDictionary dictionaryWithDictionary:@{USER_NAME:[AppHelper userName]}];
            DLog(@"User status = %@",[AppHelper userStatus]);   
                [FBAppEvents logEvent:@"Native_SignUp" parameters:analyticsParams];
               [self performSegueWithIdentifier:@"FromSignUpPersonalSpotsTab" sender:nil];
            
        }else{
            DLog(@"Error : %@",error);
            [AppHelper showAlert:@"Oops!"
                         message:@"There was an issue signing you up for Suba.Please do not despair.Try again"buttons:@[@"I'll try again"] delegate:nil];
        }
    }];
  }
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SignUpToPhotoStream"]) {
        PhotoStreamViewController *pVC = segue.destinationViewController;
        NSDictionary *streamInfo = (NSDictionary *)sender;
        pVC.spotID = streamInfo[@"streamId"];
        pVC.spotName = streamInfo[@"streamName"];
        pVC.numberOfPhotos = [streamInfo[@"photos"] integerValue];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACTIVE_SPOT_CODE];
        
    }else if ([segue.identifier isEqualToString:@"Agree_Terms_Segue"]){
        
        NSURL *url = nil;
        TermsViewController *tVC = segue.destinationViewController;
        url = [NSURL URLWithString:@"http://www.subaapp.com/terms.html"];
        tVC.navigationItem.title = @"Terms";
        tVC.urlToLoad = url;
        
    }else if ([segue.identifier isEqualToString:@"Agree_Privacy_Segue"]){
        NSURL *url = nil;
        TermsViewController *tVC = segue.destinationViewController;
        url = [NSURL URLWithString:@"http://www.subaapp.com/privacy.html"];
        tVC.navigationItem.title = @"Privacy";
        tVC.urlToLoad = url;

        
    }
}



#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    DLog(@"encode");
    self.email = self.emailField.text;
    self.userName = self.userNameField.text;
    [coder encodeObject:self.email forKey:UserEmailKey];
    [coder encodeObject:self.userName forKey:UserNameKey];
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    DLog(@"decode");
    self.email = [coder decodeObjectForKey:UserEmailKey];
    self.userName = [coder decodeObjectForKey:UserNameKey];
    
}

-(void)applicationFinishedRestoringState
{
    // Inflate view from freezed state
    self.emailField.text = self.email;
    self.userNameField.text = self.userName;
}

#pragma mark - Handle the keyboard
/*-(void)keyboardWillShowNotification:(NSNotification *)aNotification
{
    DLog(@"Keyboard notification Info -%@",[aNotification description]);
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *keyboardFrame = userInfo[UIKeyboardFrameBeginUserInfoKey];
    CGFloat frame = keyboardFrame.CGSizeValue.height;
    
    UIScrollView *scrollView = (UIScrollView *)[self.view viewWithTag:100];
    [scrollView setContentOffset:CGPointMake(scrollView.frame.origin.x, scrollView.frame.origin.y + frame) animated:YES];
}

-(void)keyboardWillHidesNotification:(NSNotification *)aNotification
{
    DLog(@"Keyboard notification Info - %@",[aNotification description]);
}*/

@end
