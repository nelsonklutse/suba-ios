//
//  SignUpViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/6/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "SignUpViewController.h"

@interface SignUpViewController ()<UITextFieldDelegate>



@property (copy,nonatomic) NSString *userName;
@property (copy,nonatomic) NSString *email;
@property (copy,nonatomic) NSString *password;

@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *userNameCheckerIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *signUpActivityIndicator;

- (void)checkUserName:(NSString *)userName;
- (void)createUserAccount:(NSDictionary *)params;

@end

@implementation SignUpViewController

bool isUserNameAvailable = NO;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.signUpButton.enabled = NO;
}

-(void)viewWillAppear:(BOOL)animated{
    [self.emailField becomeFirstResponder];
    [super viewWillAppear:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signUp:(UIButton *)sender {
    
    //Save these in a model
    self.email = self.emailField.text;
    
    self.userName = self.userNameField.text;
    self.password = self.passwordField.text;
    
    if (![self.emailField.text isEqualToString:@""] &&
        ![self.userNameField.text isEqualToString:@""]){
        // Now all the fields are not empty
        
        //1. Let's first check whether the email is correct
        if ([AppHelper validateEmail:self.emailField.text]){
            // If the email is correct,begin to process everything else
            
            
            if ([self.userNameField.text isEqualToString:self.passwordField.text]){
                
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"Yet to sign up"
                                          message:@"Your username and password appear to be the same"
                                          delegate:nil
                                          cancelButtonTitle:@"I'll check"
                                          otherButtonTitles:nil];
                
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
                                      message:@"We could not verfiy your email address format"
                                      delegate:nil
                                      cancelButtonTitle:@"I'll check"
                                      otherButtonTitles:nil];
            
            [alertView show];
        }
    }
}

- (IBAction)dismissKeypad:(UIButton *)sender {
    [self.emailField resignFirstResponder];
    [self.userNameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}



#pragma mark - UITextField Delegate Methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.emailField)[self.userNameField becomeFirstResponder];
    if (textField == self.userNameField)[self.passwordField becomeFirstResponder];
    
    if (textField == self.passwordField && ![textField.text isEqualToString:@""]) {
        
        if (![self.emailField.text isEqualToString:@""] &&
            ![self.userNameField.text isEqualToString:@""]){
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
        }
        
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
    
    if (textField == self.passwordField) {
        if (![self.emailField.text isEqualToString:@""] && ![self.userNameField.text isEqualToString:@""]){
            //DLog(@"SignUp Button enabled");
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
            [self performSegueWithIdentifier:@"FromSignUpPersonalSpotsTab" sender:nil];
        }else{
            DLog(@"Error : %@",error);
        }
    }];
  }
}

@end
